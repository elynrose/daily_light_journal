import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/entry_storage.dart';
import '../services/song_storage.dart';
import '../theme/app_colors.dart';
import 'song_detail_screen.dart';
import 'song_form_screen.dart';

class SongsScreen extends StatefulWidget {
  final VoidCallback onAddedToNotes;

  const SongsScreen({super.key, required this.onAddedToNotes});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final SongStorage _songStorage = SongStorage.instance;
  final EntryStorage _entryStorage = EntryStorage.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSongs() {
    setState(() {
      _songs = _songStorage.searchSongs(_searchController.text);
    });
  }

  Future<void> _openAddPage() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const SongFormScreen()),
    );
    if (saved == true) _loadSongs();
  }

  Future<void> _openDetailPage(Song song) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => SongDetailScreen(song: song)),
    );
    if (saved == true) _loadSongs();
  }

  Future<void> _openEditPage(Song song) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => SongFormScreen(song: song)),
    );
    if (saved == true) _loadSongs();
  }

  Future<void> _addToNotes(Song song) async {
    await _entryStorage.addSongToTodayNotes(song);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${song.title}" added to today\'s notes')),
    );
    widget.onAddedToNotes();
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete song?'),
        content: Text('Delete "${song.title}" from your song list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _songStorage.deleteSong(song.id);
    _loadSongs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Song deleted from list')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.seafoam,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Songs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _openAddPage,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.text,
                    iconSize: 28,
                    tooltip: 'Add to list',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  filled: true,
                  fillColor: AppColors.offWhite,
                  prefixIcon: const Icon(Icons.search, color: AppColors.text),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: AppColors.outlineInputBorder,
                  enabledBorder: AppColors.outlineInputBorder,
                  focusedBorder: AppColors.outlineInputBorder,
                ),
                style: const TextStyle(color: AppColors.text),
                onChanged: (_) => _loadSongs(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No songs in your list yet',
                            style: const TextStyle(color: AppColors.text),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _openAddPage,
                            icon: const Icon(Icons.add),
                            label: const Text('Add to List'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _songs.length,
                      separatorBuilder: (_, __) => AppColors.listSeparator(),
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 8, right: 0),
                          title: Text(
                            song.title.isEmpty ? '(Untitled)' : song.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                          subtitle: song.songbookRef.isNotEmpty
                              ? Text('${song.key.isNotEmpty ? '${song.key} · ' : ''}${song.songbookRef}')
                              : (song.key.isNotEmpty ? Text(song.key) : null),
                          onTap: () => _openDetailPage(song),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (song.number.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    song.number,
                                    style: const TextStyle(color: AppColors.text),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.note_add_outlined),
                                color: AppColors.text,
                                tooltip: 'Add to Notes',
                                onPressed: () => _addToNotes(song),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: AppColors.text,
                                tooltip: 'Edit',
                                onPressed: () => _openEditPage(song),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: AppColors.text,
                                tooltip: 'Delete',
                                onPressed: () => _deleteSong(song),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
