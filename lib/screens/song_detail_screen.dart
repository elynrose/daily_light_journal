import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/app_preferences_service.dart';
import '../services/song_storage.dart';
import '../theme/app_colors.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  static const _autosaveDelay = Duration(milliseconds: 800);

  final SongStorage _storage = SongStorage.instance;
  late final TextEditingController _lyricsController;
  late String _savedLyrics;
  Timer? _autosaveTimer;
  bool _savedChanges = false;

  @override
  void initState() {
    super.initState();
    _savedLyrics = widget.song.lyrics;
    _lyricsController = TextEditingController(text: _savedLyrics);
    _lyricsController.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    unawaited(_flushSave());
    _lyricsController.removeListener(_scheduleAutosave);
    _lyricsController.dispose();
    super.dispose();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, () => unawaited(_flushSave()));
  }

  Future<void> _flushSave() async {
    _autosaveTimer?.cancel();
    if (_lyricsController.text == _savedLyrics) return;

    await _storage.saveSong(
      id: widget.song.id,
      title: widget.song.title,
      key: widget.song.key,
      lyrics: _lyricsController.text,
      number: widget.song.number,
      songbookRef: widget.song.songbookRef,
    );

    if (!mounted) return;
    setState(() {
      _savedLyrics = _lyricsController.text;
      _savedChanges = true;
    });
  }

  Future<void> _saveAndPop() async {
    await _flushSave();
    if (!mounted) return;
    Navigator.pop(context, _savedChanges);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppPreferencesService.instance,
      builder: (context, _) {
        final fontScale =
            AppPreferencesService.instance.prefs.lyricsFontScale;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _saveAndPop();
          },
          child: Scaffold(
            backgroundColor: AppColors.offWhite,
            appBar: AppBar(
              title: Text(
                widget.song.title.isEmpty ? '(Untitled)' : widget.song.title,
              ),
              backgroundColor: AppColors.dustyBlue,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => unawaited(_saveAndPop()),
              ),
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.song.key.isNotEmpty)
                          Text(
                            'Key: ${widget.song.key}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        if (widget.song.songbookRef.isNotEmpty) ...[
                          if (widget.song.key.isNotEmpty)
                            const SizedBox(height: 4),
                          Text(
                            widget.song.songbookRef,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Lyrics',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: _lyricsController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Tap to add lyrics…',
                          hintStyle: TextStyle(
                            color: AppColors.text,
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: 16 * fontScale,
                          height: 1.5,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
