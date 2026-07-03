import 'dart:async';

import 'package:flutter/material.dart';

import '../models/bible_translation.dart';
import '../models/bible_verse.dart';
import '../services/app_preferences_service.dart';
import '../services/bible_storage.dart';
import '../services/entry_storage.dart';
import '../services/journal_context.dart';
import '../theme/app_colors.dart';

class BibleScreen extends StatefulWidget {
  final String? initialReference;
  final VoidCallback? onAddedToScriptures;

  const BibleScreen({
    super.key,
    this.initialReference,
    this.onAddedToScriptures,
  });

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final BibleStorage _bibleStorage = BibleStorage.instance;
  final _prefsService = AppPreferencesService.instance;
  final EntryStorage _entryStorage = EntryStorage.instance;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _verseKeys = {};

  List<BibleVerse> _verses = [];
  bool _loading = true;
  String? _error;
  String? _loadedTranslationId;
  final Set<String> _highlightedReferences = {};

  String? _selectedBook;
  int? _selectedChapter;
  int? _selectedVerse;

  @override
  void initState() {
    super.initState();
    _prefsService.addListener(_onPrefsChanged);
    unawaited(_loadBible());
  }

  @override
  void didUpdateWidget(covariant BibleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialReference != widget.initialReference &&
        widget.initialReference != null &&
        !_loading) {
      _applySelectionFromReference(widget.initialReference!);
    }
  }

  @override
  void dispose() {
    _prefsService.removeListener(_onPrefsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    final translationId = _prefsService.prefs.bibleTranslationId;
    if (translationId != _loadedTranslationId && mounted) {
      unawaited(_reloadForTranslation(translationId));
    }
  }

  Future<void> _loadBible() async {
    await _reloadForTranslation(_prefsService.prefs.bibleTranslationId);
  }

  Future<void> _reloadForTranslation(String translationId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _bibleStorage.load(translationId: translationId);
      if (!mounted) return;

      _loadedTranslationId = translationId;
      setState(() {
        _loading = false;
      });
      _initializeSelection();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Bible';
        _loading = false;
      });
    }
  }

  Future<void> _changeTranslation(String? translationId) async {
    if (translationId == null) return;
    await _prefsService.updateBibleTranslation(translationId);
  }

  void _initializeSelection() {
    final initialReference = widget.initialReference;
    if (initialReference != null &&
        _applySelectionFromReference(initialReference)) {
      return;
    }

    final books = _bibleStorage.books;
    if (books.isEmpty) {
      setState(() => _verses = const []);
      return;
    }

    final book = (_selectedBook != null && books.contains(_selectedBook))
        ? _selectedBook!
        : books.first;
    _applySelection(book: book, chapter: _selectedChapter, verse: _selectedVerse);
  }

  bool _applySelectionFromReference(String reference) {
    final parsed = BibleStorage.parseVerseReference(reference);
    if (parsed == null) return false;
    final (book, chapter, verse) = parsed;
    if (!_bibleStorage.books.contains(book)) return false;
    _applySelection(book: book, chapter: chapter, verse: verse, scroll: true);
    return true;
  }

  /// Loads the whole chapter starting at the selected verse.
  void _applySelection({
    required String book,
    int? chapter,
    int? verse,
    bool scroll = false,
  }) {
    final chapters = _bibleStorage.chaptersForBook(book);
    if (chapters.isEmpty) return;

    final selectedChapter =
        (chapter != null && chapters.contains(chapter)) ? chapter : chapters.first;
    final chapterVerseNumbers =
        _bibleStorage.versesForBookChapter(book, selectedChapter);
    final selectedVerse = (verse != null && chapterVerseNumbers.contains(verse))
        ? verse
        : (chapterVerseNumbers.isNotEmpty ? chapterVerseNumbers.first : 1);

    final chapterVerses =
        _bibleStorage.chapterVersesFrom(book, selectedChapter, selectedVerse);

    setState(() {
      _selectedBook = book;
      _selectedChapter = selectedChapter;
      _selectedVerse = selectedVerse;
      _verses = chapterVerses;
      _highlightedReferences
        ..clear()
        ..add('$book $selectedChapter:$selectedVerse');
    });

    if (scroll && chapterVerses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToReference(chapterVerses.first.reference);
      });
    }
  }

  void _onBookChanged(String? book) {
    if (book == null) return;
    _applySelection(book: book);
  }

  void _onChapterChanged(int? chapter) {
    final book = _selectedBook;
    if (book == null || chapter == null) return;
    _applySelection(book: book, chapter: chapter);
  }

  void _onVerseChanged(int? verse) {
    final book = _selectedBook;
    final chapter = _selectedChapter;
    if (book == null || chapter == null || verse == null) return;
    _applySelection(book: book, chapter: chapter, verse: verse, scroll: true);
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

  static TextStyle _bookStyle(double scale) => TextStyle(
        fontSize: 26 * scale,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        height: 1.15,
        letterSpacing: 0.3,
      );

  static TextStyle _chapterStyle(double scale) => TextStyle(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.25,
      );

  static TextStyle _verseNumberStyle(double scale) => TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.5,
      );

  static TextStyle _verseTextStyle(double scale) => TextStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w300,
        color: const Color(0xFF3A3A3A),
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

  Future<void> _addVerseToNotes(BibleVerse verse) async {
    final journal = JournalContext.instance;
    await _entryStorage.appendScriptureNotes(
      verse.toNotesLine(),
      date: journal.date,
      period: journal.period,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${verse.reference} added to scripture notes')),
    );
    widget.onAddedToScriptures?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppPreferencesService.instance,
      builder: (context, _) {
        final fontScale = AppPreferencesService.instance.prefs.bibleFontScale;
        final translationId =
            AppPreferencesService.instance.prefs.bibleTranslationId;
        return _buildScaffold(fontScale, translationId);
      },
    );
  }

  Widget _buildScaffold(double fontScale, String translationId) {
    return ColoredBox(
      color: AppColors.mintGreen,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: translationId,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.text,
                          ),
                          dropdownColor: Colors.white,
                          items: BibleTranslation.all
                              .map(
                                (translation) => DropdownMenuItem(
                                  value: translation.id,
                                  child: Text(translation.label),
                                ),
                              )
                              .toList(),
                          onChanged: _loading
                              ? null
                              : (value) => unawaited(_changeTranslation(value)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildReferenceSelectors(),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(fontScale)),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceSelectors() {
    final books = _bibleStorage.books;
    final chapters =
        _selectedBook != null ? _bibleStorage.chaptersForBook(_selectedBook!) : <int>[];
    final verses = (_selectedBook != null && _selectedChapter != null)
        ? _bibleStorage.versesForBookChapter(_selectedBook!, _selectedChapter!)
        : <int>[];

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _SelectorBox(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedBook,
              hint: const Text('Book'),
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              items: books
                  .map(
                    (book) => DropdownMenuItem(
                      value: book,
                      child: Text(book, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : _onBookChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _SelectorBox(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedChapter,
              hint: const Text('Ch'),
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              items: chapters
                  .map(
                    (chapter) => DropdownMenuItem(
                      value: chapter,
                      child: Text('$chapter'),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : _onChapterChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _SelectorBox(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedVerse,
              hint: const Text('Vs'),
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              items: verses
                  .map(
                    (verse) => DropdownMenuItem(
                      value: verse,
                      child: Text('$verse'),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : _onVerseChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(double fontScale) {
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
      return const Center(
        child: Text(
          'No verses found',
          style: TextStyle(color: AppColors.text),
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
                  Center(
                    child: Text(
                      book,
                      style: _bookStyle(fontScale),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (chapter.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Chapter $chapter', style: _chapterStyle(fontScale)),
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
                            style: _verseNumberStyle(fontScale),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            verse.text,
                            style: _verseTextStyle(fontScale),
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

class _SelectorBox extends StatelessWidget {
  final Widget child;

  const _SelectorBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(child: child),
      ),
    );
  }
}
