import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/study_audio_attachment.dart';
import '../theme/app_colors.dart';

class EmbeddedAudioPlayer extends StatefulWidget {
  final StudyAudioAttachment audio;
  final VoidCallback? onRemove;

  const EmbeddedAudioPlayer({
    super.key,
    required this.audio,
    this.onRemove,
  });

  @override
  State<EmbeddedAudioPlayer> createState() => _EmbeddedAudioPlayerState();
}

class _EmbeddedAudioPlayerState extends State<EmbeddedAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _errorMessage;
  bool _isPrepared = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant EmbeddedAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio.enclosureUrl != widget.audio.enclosureUrl) {
      unawaited(_reloadAudio());
    }
  }

  Future<void> _initPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _positionSub = _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration ?? Duration.zero);
    });
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
    });

    await _reloadAudio();
  }

  Future<void> _reloadAudio() async {
    setState(() {
      _errorMessage = null;
      _isPrepared = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
    });

    try {
      await _player.stop();
      await _player.setUrl(widget.audio.enclosureUrl);
      if (!mounted) return;
      setState(() => _isPrepared = true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load audio';
        _isPrepared = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (!_isPrepared || _errorMessage != null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      final session = await AudioSession.instance;
      await session.setActive(true);
      await _player.play();
    }
  }

  Future<void> _seekTo(double value) async {
    await _player.seek(Duration(milliseconds: value.round()));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_playerStateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = widget.audio;
    final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _errorMessage == null && !_isLoading
                      ? () => unawaited(_togglePlayback())
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(
                    _isLoading
                        ? Icons.hourglass_top
                        : _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                    size: 36,
                    color: AppColors.text,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.title.isEmpty ? '(Untitled episode)' : audio.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.text,
                          ),
                        ),
                        if (audio.author.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            audio.author,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close, size: 18, color: AppColors.text),
                  ),
              ],
            ),
            if (_isPrepared && _errorMessage == null) ...[
              Slider(
                value: _position.inMilliseconds.clamp(0, maxMs).toDouble(),
                max: maxMs.toDouble(),
                onChanged: _seekTo,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(fontSize: 11, color: AppColors.text),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(fontSize: 11, color: AppColors.text),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
