import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/sermon_feed_item.dart';
import '../theme/app_colors.dart';

class SermonPlayerScreen extends StatefulWidget {
  final SermonFeedItem item;

  const SermonPlayerScreen({
    super.key,
    required this.item,
  });

  @override
  State<SermonPlayerScreen> createState() => _SermonPlayerScreenState();
}

class _SermonPlayerScreenState extends State<SermonPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _interruptionSub = session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            unawaited(_player.setVolume(0.5));
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            unawaited(_player.pause());
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            unawaited(_player.setVolume(1.0));
          case AudioInterruptionType.pause:
            unawaited(_player.play());
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

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

    try {
      await session.setActive(true);
      await _player.setUrl(widget.item.audioUrl);
      await _player.play();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load audio: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seekTo(double value) async {
    final target = Duration(milliseconds: value.round());
    await _player.seek(target);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_playerStateSub?.cancel());
    unawaited(_interruptionSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final maxMs = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.dustyBlue,
        foregroundColor: AppColors.text,
        title: const Text('Sermon'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: item.coverImage != null && item.coverImage!.isNotEmpty
                        ? Image.network(
                            item.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _coverPlaceholder(),
                          )
                        : _coverPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                item.sermonTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.preachedBy,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              if (item.displayDateLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.displayDateLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ],
              if (item.language != null && item.language!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.language!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                ),
              ],
              const Spacer(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Slider(
                value: _position.inMilliseconds.clamp(0, maxMs).toDouble(),
                max: maxMs.toDouble(),
                onChanged: _errorMessage == null ? _seekTo : null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: IconButton(
                  iconSize: 56,
                  onPressed: _errorMessage == null && !_isLoading
                      ? () => unawaited(_togglePlayback())
                      : null,
                  icon: Icon(
                    _isLoading
                        ? Icons.hourglass_top
                        : _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return const Center(
      child: Icon(
        Icons.podcasts,
        size: 72,
        color: AppColors.text,
      ),
    );
  }
}
