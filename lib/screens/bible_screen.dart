import 'package:flutter/material.dart';

import '../models/bible_verse.dart';
import '../services/bible_storage.dart';
import '../services/entry_storage.dart';
import '../theme/app_colors.dart';

class BibleScreen extends StatefulWidget {
  final String? initialReference;

  const BibleScreen({super.key, this.initialReference});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final BibleStorage _bibleStorage = BibleStorage.instance;
  final EntryStorage _entryStorage = EntryStorage.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _verseKeys = {};

  List<BibleVerse> _verses = [];
  bool _loading = true;
  String? _error;
  final Set<String> _highlightedReferences = {};

  @override
  void initState() {
    super.initState();
    _loadBible();
  }

  @override
  void didUpdateWidget(covariant BibleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialReference != widget.initialReference &&
        widget.initialReference != null &&
        !_loading) {
      _applyInitialReference(widget.initialReference!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

      final initialReference = widget.initialReference;
      if (initialReference != null) {
        _applyInitialReference(initialReference);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Bible';
        _loading = false;
      });
    }
  }

  void _applyInitialReference(String reference) {
    final verses = _bibleStorage.versesForReferenceQuery(reference);
    if (verses.isEmpty) {
      _searchController.text = reference;
      setState(() {
        _verses = _bibleStorage.search(reference);
        _highlightedReferences.clear();
      });
      return;
    }

    _searchController.text = reference;
    setState(() {
      _verses = verses;
      _highlightedReferences
        ..clear()
        ..addAll(verses.map((verse) => verse.reference));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToReference(verses.first.reference);
    });
  }

  void _scrollToReference(String reference) {
    final key = _verseKeys[reference];
    final context = key?.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  GlobalKey _keyForVerse(String reference) {
    return _verseKeys.putIfAbsent(reference, GlobalKey.new);
  }

  static const _bookStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1.15,
    letterSpacing: 0.3,
  );

  static const _chapterStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.25,
  );

  static const _verseNumberStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.5,
  );

  static const _verseTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w300,
    color: Color(0xFF3A3A3A),
    height: 1.55,
  );

  (String book, String chapter) _parseChapterKey(String chapterKey) {
    final parts = chapterKey.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      final last = parts.last;
      if (RegExp(r'^\d+$').hasMatch(last)) {
        return (parts.sublist(0, parts.length - 1).join(' '), last);
      }
    }
    return (chapterKey, '');
  }

  String _verseNumber(String reference) {
    final colonIndex = reference.lastIndexOf(':');
    if (colonIndex < 0 || colonIndex == reference.length - 1) {
      return reference;
    }
    return reference.substring(colonIndex + 1);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _highlightedReferences.clear();
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chapterKeys.length,
      separatorBuilder: (_, __) => AppColors.listSeparator(),
      itemBuilder: (context, chapterIndex) {
        final chapterKey = chapterKeys[chapterIndex];
        final chapterVerses = chapters[chapterKey]!;
        final (book, chapter) = _parseChapterKey(chapterKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book, style: _bookStyle),
                  if (chapter.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Chapter $chapter', style: _chapterStyle),
                  ],
                ],
              ),
            ),
            ...chapterVerses.map(
              (verse) => Padding(
                key: _keyForVerse(verse.reference),
                padding: const EdgeInsets.only(bottom: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _highlightedReferences.contains(verse.reference)
                        ? AppColors.dustyBlue.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            _verseNumber(verse.reference),
                            style: _verseNumberStyle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            verse.text,
                            style: _verseTextStyle,
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
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
