import 'package:flutter/material.dart';

import '../models/bible_verse.dart';
import '../services/bible_storage.dart';
import '../services/entry_storage.dart';
import '../theme/app_colors.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final BibleStorage _bibleStorage = BibleStorage.instance;
  final EntryStorage _entryStorage = EntryStorage.instance;
  final TextEditingController _searchController = TextEditingController();

  List<BibleVerse> _verses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBible();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBible() async {
    try {
      await _bibleStorage.load();
      if (!mounted) return;
      setState(() {
        _verses = _bibleStorage.allVerses;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Bible';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _verses = _bibleStorage.search(query);
    });
  }

  Future<void> _addVerseToNotes(BibleVerse verse) async {
    await _entryStorage.appendScriptureNotes(verse.toNotesLine());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${verse.reference} added to scripture notes')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mintGreen,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Bible',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                  letterSpacing: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search reference or text',
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
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.text),
        ),
      );
    }

    if (_verses.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'No verses found'
              : 'No matches for "${_searchController.text.trim()}"',
          style: const TextStyle(color: AppColors.text),
        ),
      );
    }

    final chapters = BibleStorage.groupByChapter(_verses);
    final chapterKeys = chapters.keys.toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chapterKeys.length,
      separatorBuilder: (_, __) => AppColors.listSeparator(),
      itemBuilder: (context, chapterIndex) {
        final chapterKey = chapterKeys[chapterIndex];
        final chapterVerses = chapters[chapterKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                chapterKey,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
            ),
            ...chapterVerses.map(
              (verse) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            verse.reference,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _addVerseToNotes(verse),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Add to scripture notes',
                          icon: const Icon(
                            Icons.add,
                            size: 20,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verse.text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
