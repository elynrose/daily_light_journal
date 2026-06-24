import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song_storage.dart';
import '../theme/app_colors.dart';

class SongFormScreen extends StatefulWidget {
  final Song? song;

  const SongFormScreen({super.key, this.song});

  bool get isEditing => song != null;

  @override
  State<SongFormScreen> createState() => _SongFormScreenState();
}

class _SongFormScreenState extends State<SongFormScreen> {
  final SongStorage _songStorage = SongStorage.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.song != null) {
      _titleController.text = widget.song!.title;
      _keyController.text = widget.song!.key;
      _lyricsController.text = widget.song!.lyrics;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keyController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _saveToList() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Title is required');
      return;
    }

    await _songStorage.saveSong(
      id: widget.song?.id,
      title: title,
      key: _keyController.text,
      lyrics: _lyricsController.text,
    );

    if (!mounted) return;
    _showMessage(widget.isEditing ? 'Song updated' : 'Added to list');
    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Song' : 'Add Song'),
        backgroundColor: AppColors.dustyBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FormField(label: 'Title', controller: _titleController),
              const SizedBox(height: 12),
              _FormField(label: 'Key', controller: _keyController),
              const SizedBox(height: 12),
              _FormField(
                label: 'Lyrics',
                controller: _lyricsController,
                maxLines: 10,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveToList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dustyBlue,
                  foregroundColor: AppColors.text,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(widget.isEditing ? 'Update' : 'Add to List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.white,
        border: AppColors.outlineInputBorder,
        enabledBorder: AppColors.outlineInputBorder,
        focusedBorder: AppColors.outlineInputBorder,
      ),
    );
  }
}
