import 'dart:async';

import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../models/song.dart';
import '../services/entry_storage.dart';
import '../services/song_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/linked_scripture_field.dart';
import '../widgets/quote_pages_field.dart';
import '../widgets/side_category_tabs.dart';
import 'song_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  final EntryCategory initialCategory;
  final DateTime? initialDate;
  final ServicePeriod? initialPeriod;
  final ValueChanged<String>? onScriptureReferenceTap;

  const JournalScreen({
    super.key,
    this.initialCategory = EntryCategory.song,
    this.initialDate,
    this.initialPeriod,
    this.onScriptureReferenceTap,
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _autosaveDelay = Duration(milliseconds: 800);

  final EntryStorage _storage = EntryStorage.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _preachedByController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _preachedByFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  late DateTime _selectedDate;
  late EntryCategory _selectedCategory;
  late ServicePeriod _selectedPeriod;
  String? _currentEntryId;
  Timer? _autosaveTimer;
  bool _isLoading = false;
  bool _isEditingTitle = false;
  bool _isEditingPreachedBy = false;
  List<DailySongItem> _songItems = [];
  List<String> _quotePages = [''];

  bool get _isSongTab => _selectedCategory == EntryCategory.song;
  bool get _isQuoteTab => _selectedCategory == EntryCategory.quote;
  bool get _isSermonTab =>
      _selectedCategory == EntryCategory.quote ||
      _selectedCategory == EntryCategory.scripture;

  @override
  void initState() {
    super.initState();
    _selectedDate = EntryStorage.normalizeDate(
      widget.initialDate ?? DateTime.now(),
    );
    _selectedCategory = widget.initialCategory;
    _selectedPeriod =
        widget.initialPeriod ?? servicePeriodFromTime(DateTime.now());
    _titleController.addListener(_scheduleAutosave);
    _preachedByController.addListener(_scheduleAutosave);
    _notesController.addListener(_scheduleAutosave);
    _titleFocusNode.addListener(_onTitleFocusChange);
    _preachedByFocusNode.addListener(_onPreachedByFocusChange);
    _notesFocusNode.addListener(_onNotesFocusChange);
    _loadEntryForCurrentSelection();
  }

  void _onNotesFocusChange() {
    if (mounted) setState(() {});
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      setState(() {
        _isEditingTitle = false;
      });
    }
  }

  void _onPreachedByFocusChange() {
    if (!_preachedByFocusNode.hasFocus && _isEditingPreachedBy) {
      setState(() {
        _isEditingPreachedBy = false;
      });
    }
  }

  void _startEditingPreachedBy() {
    setState(() {
      _isEditingPreachedBy = true;
    });
    _preachedByFocusNode.requestFocus();
  }

  void _startEditingTitle() {
    setState(() {
      _isEditingTitle = true;
    });
    _titleFocusNode.requestFocus();
  }

  @override
  void didUpdateWidget(covariant JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory ||
        oldWidget.initialDate != widget.initialDate ||
        oldWidget.initialPeriod != widget.initialPeriod) {
      _switchContext(
        category: widget.initialCategory,
        date: widget.initialDate ?? _selectedDate,
        period: widget.initialPeriod ?? _selectedPeriod,
      );
    }
  }

  void _scheduleAutosave() {
    if (_isLoading || _isSongTab) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, () {
      unawaited(_flushSave());
    });
  }

  String get _fieldSlotId => EntryStorage.dateCategoryKey(
        _selectedDate,
        _selectedCategory,
        period: _selectedPeriod,
      );

  void _applyFieldsFromEntry(Entry? entry) {
    _titleController.removeListener(_scheduleAutosave);
    _preachedByController.removeListener(_scheduleAutosave);
    _notesController.removeListener(_scheduleAutosave);

    final sermonTitle = _isSermonTab
        ? _storage.getSermonTitleSync(_selectedDate, period: _selectedPeriod)
        : entry?.title ?? '';
    final preachedBy = _isSermonTab
        ? _storage.getSermonPreachedBySync(_selectedDate, period: _selectedPeriod)
        : '';
    final notes = _selectedCategory == EntryCategory.scripture
        ? entry?.notes ?? ''
        : '';
    final quotePages = _selectedCategory == EntryCategory.quote
        ? _pagesFromEntry(entry)
        : [''];

    _titleController.value = TextEditingValue(
      text: sermonTitle,
      selection: TextSelection.collapsed(offset: sermonTitle.length),
    );
    _preachedByController.value = TextEditingValue(
      text: preachedBy,
      selection: TextSelection.collapsed(offset: preachedBy.length),
    );
    _notesController.value = TextEditingValue(
      text: notes,
      selection: TextSelection.collapsed(offset: notes.length),
    );
    _songItems = List<DailySongItem>.from(entry?.songItems ?? []);
    _quotePages = quotePages;

    _titleController.addListener(_scheduleAutosave);
    _preachedByController.addListener(_scheduleAutosave);
    _notesController.addListener(_scheduleAutosave);
  }

  List<String> _pagesFromEntry(Entry? entry) {
    final pages = entry?.resolvedNotePages ?? const <String>[];
    if (pages.isEmpty) return [''];
    return List<String>.from(pages);
  }

  void _onQuotePagesChanged(List<String> pages) {
    _quotePages = pages;
    _scheduleAutosave();
  }

  Future<void> _flushSave() async {
    _autosaveTimer?.cancel();

    final saveDate = _selectedDate;
    final saveCategory = _selectedCategory;
    final savePeriod = _selectedPeriod;

    if (saveCategory == EntryCategory.song) {
      await _saveSongList(saveDate, savePeriod);
      return;
    }

    final sermonTitle = _titleController.text.trim();
    final notes = _isQuoteTab
        ? ''
        : _notesController.text.trim();
    final quotePages = _isQuoteTab ? List<String>.from(_quotePages) : const <String>[];
    final hasQuoteContent =
        quotePages.any((page) => page.trim().isNotEmpty);
    final hasScriptureContent = notes.isNotEmpty;

    await _storage.setSermonTitle(
      saveDate,
      sermonTitle,
      period: savePeriod,
    );
    await _storage.setSermonPreachedBy(
      saveDate,
      _preachedByController.text.trim(),
      period: savePeriod,
    );

    if (_isQuoteTab) {
      if (!hasQuoteContent) {
        await _storage.deleteEntryForDateCategoryAndPeriod(
          saveDate,
          saveCategory,
          period: savePeriod,
        );
        if (mounted &&
            saveCategory == _selectedCategory &&
            savePeriod == _selectedPeriod &&
            EntryStorage.isSameDate(saveDate, _selectedDate)) {
          setState(() {
            _currentEntryId = null;
          });
        }
        return;
      }

      final entry = Entry(
        id: EntryStorage.dateCategoryKey(
          saveDate,
          saveCategory,
          period: savePeriod,
        ),
        date: saveDate,
        title: '',
        notes: '',
        category: saveCategory,
        period: savePeriod,
        notePages: quotePages,
      );

      await _storage.saveEntry(entry);

      if (!mounted) return;

      if (saveCategory == _selectedCategory &&
          savePeriod == _selectedPeriod &&
          EntryStorage.isSameDate(saveDate, _selectedDate) &&
          _currentEntryId != entry.id) {
        setState(() {
          _currentEntryId = entry.id;
        });
      }
      return;
    }

    if (!hasScriptureContent) {
      await _storage.deleteEntryForDateCategoryAndPeriod(
        saveDate,
        saveCategory,
        period: savePeriod,
      );
      if (mounted &&
          saveCategory == _selectedCategory &&
          savePeriod == _selectedPeriod &&
          EntryStorage.isSameDate(saveDate, _selectedDate)) {
        setState(() {
          _currentEntryId = null;
        });
      }
      return;
    }

    final entry = Entry(
      id: EntryStorage.dateCategoryKey(
        saveDate,
        saveCategory,
        period: savePeriod,
      ),
      date: saveDate,
      title: '',
      notes: notes,
      category: saveCategory,
      period: savePeriod,
    );

    await _storage.saveEntry(entry);

    if (!mounted) return;

    if (saveCategory == _selectedCategory &&
        savePeriod == _selectedPeriod &&
        EntryStorage.isSameDate(saveDate, _selectedDate) &&
        _currentEntryId != entry.id) {
      setState(() {
        _currentEntryId = entry.id;
      });
    }
  }

  Future<void> _saveSongList(
    DateTime saveDate,
    ServicePeriod savePeriod,
  ) async {
    if (_songItems.isEmpty) {
      await _storage.deleteEntryForDateCategoryAndPeriod(
        saveDate,
        EntryCategory.song,
        period: savePeriod,
      );
      if (mounted &&
          _selectedCategory == EntryCategory.song &&
          _selectedPeriod == savePeriod &&
          EntryStorage.isSameDate(saveDate, _selectedDate)) {
        setState(() {
          _currentEntryId = null;
        });
      }
      return;
    }

    final entry = Entry(
      id: EntryStorage.dateCategoryKey(
        saveDate,
        EntryCategory.song,
        period: savePeriod,
      ),
      date: saveDate,
      title: '',
      notes: '',
      category: EntryCategory.song,
      period: savePeriod,
      songItems: _songItems,
    );

    await _storage.saveEntry(entry);

    if (!mounted) return;

    if (_selectedCategory == EntryCategory.song &&
        _selectedPeriod == savePeriod &&
        EntryStorage.isSameDate(saveDate, _selectedDate) &&
        _currentEntryId != entry.id) {
      setState(() {
        _currentEntryId = entry.id;
      });
    }
  }

  Future<void> _openSongDetail(DailySongItem item) async {
    final catalogSong = SongStorage.instance.findSong(
      title: item.title,
      key: item.key,
    );
    final song = catalogSong ??
        Song(
          id: 'journal-${item.title}-${item.key}',
          title: item.title,
          key: item.key,
          lyrics: '',
        );

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SongDetailScreen(song: song)),
    );
  }

  Future<void> _removeSongItem(int index) async {
    setState(() {
      _songItems.removeAt(index);
    });
    await _saveSongList(_selectedDate, _selectedPeriod);
  }

  void _loadEntryForCurrentSelection() {
    _isLoading = true;
    _autosaveTimer?.cancel();

    final existing = _storage.getEntrySync(
      _selectedDate,
      _selectedCategory,
      period: _selectedPeriod,
    );

    _applyFieldsFromEntry(existing);

    setState(() {
      _currentEntryId = existing?.id;
      _isLoading = false;
      _isEditingTitle = false;
      _isEditingPreachedBy = false;
    });
  }

  Future<void> _switchContext({
    required EntryCategory category,
    required DateTime date,
    ServicePeriod? period,
  }) async {
    _isLoading = true;
    _autosaveTimer?.cancel();
    await _flushSave();
    if (!mounted) return;

    setState(() {
      _selectedCategory = category;
      _selectedDate = EntryStorage.normalizeDate(date);
      if (period != null) {
        _selectedPeriod = period;
      }
    });
    _loadEntryForCurrentSelection();
  }

  Future<void> _changeDate(int offset) async {
    await _switchContext(
      category: _selectedCategory,
      date: _selectedDate.add(Duration(days: offset)),
      period: _selectedPeriod,
    );
  }

  Future<void> _changeCategory(EntryCategory category) async {
    if (category == _selectedCategory) return;

    _isLoading = true;
    _autosaveTimer?.cancel();
    await _flushSave();
    if (!mounted) return;

    setState(() {
      _selectedCategory = category;
    });
    _loadEntryForCurrentSelection();
  }

  Future<void> _changePeriod(ServicePeriod period) async {
    if (period == _selectedPeriod) return;

    await _switchContext(
      category: _selectedCategory,
      date: _selectedDate,
      period: period,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    final normalized = EntryStorage.normalizeDate(picked);
    if (EntryStorage.isSameDate(normalized, _selectedDate)) return;

    await _switchContext(
      category: _selectedCategory,
      date: normalized,
      period: _selectedPeriod,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    unawaited(_flushSave());
    _titleController.removeListener(_scheduleAutosave);
    _preachedByController.removeListener(_scheduleAutosave);
    _notesController.removeListener(_scheduleAutosave);
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _preachedByFocusNode.removeListener(_onPreachedByFocusChange);
    _notesFocusNode.removeListener(_onNotesFocusChange);
    _titleController.dispose();
    _preachedByController.dispose();
    _notesController.dispose();
    _titleFocusNode.dispose();
    _preachedByFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryBg = _selectedCategory.backgroundColor;
    final categoryAccent = _selectedCategory.accentColor;

    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SideCategoryTabs(
            selectedCategory: _selectedCategory,
            onCategoryChanged: _changeCategory,
          ),
          Expanded(
            child: ColoredBox(
              color: categoryBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateNavBar(
                    dateLabel: _formatDate(_selectedDate),
                    onPrevious: () => unawaited(_changeDate(-1)),
                    onNext: () => unawaited(_changeDate(1)),
                    onDateTap: () => unawaited(_pickDate()),
                    accentColor: categoryAccent,
                  ),
                  _ServicePeriodBar(
                    selected: _selectedPeriod,
                    onChanged: _changePeriod,
                    accentColor: categoryAccent,
                  ),
                  if (_isSongTab) ...[
                    Expanded(child: _buildSongList()),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          Text(
                            _isSermonTab ? 'Sermon:' : 'Title:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              key: ValueKey(
                                'title-$_fieldSlotId-${_isSermonTab ? 'sermon' : 'title'}',
                              ),
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              readOnly: !_isEditingTitle,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '',
                              ),
                              style: const TextStyle(fontSize: 16, color: AppColors.text),
                              onSubmitted: (_) {
                                _titleFocusNode.unfocus();
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: _startEditingTitle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.text,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isSermonTab)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: Row(
                          children: [
                            const Text(
                              'Preached by:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                key: ValueKey('preached-by-$_fieldSlotId'),
                                controller: _preachedByController,
                                focusNode: _preachedByFocusNode,
                                readOnly: !_isEditingPreachedBy,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.text,
                                ),
                                onSubmitted: (_) {
                                  _preachedByFocusNode.unfocus();
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: _startEditingPreachedBy,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.text,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(
                      height: AppColors.borderWidth,
                      thickness: AppColors.borderWidth,
                      color: AppColors.border,
                      indent: 12,
                      endIndent: 12,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: _isQuoteTab
                            ? QuotePagesField(
                                key: ValueKey('quote-pages-$_fieldSlotId'),
                                initialPages: _quotePages,
                                onPagesChanged: _onQuotePagesChanged,
                                onReferenceTap: (reference) {
                                  widget.onScriptureReferenceTap?.call(reference);
                                },
                              )
                            : LinkedScriptureField(
                                key: ValueKey('linked-notes-$_fieldSlotId'),
                                controller: _notesController,
                                focusNode: _notesFocusNode,
                                labelText: _selectedCategory.listTitle,
                                onReferenceTap: (reference) {
                                  widget.onScriptureReferenceTap?.call(reference);
                                },
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    if (_songItems.isEmpty) {
      return Center(
        child: Text(
          'No songs for this ${_selectedPeriod.label} service',
          style: const TextStyle(color: AppColors.text),
        ),
      );
    }

    return ListView.separated(
      key: ValueKey('songs-$_fieldSlotId'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _songItems.length,
      separatorBuilder: (_, __) => AppColors.listSeparator(),
      itemBuilder: (context, index) {
        final item = _songItems[index];
        return InkWell(
          onTap: () => unawaited(_openSongDetail(item)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.title.isEmpty ? '(Untitled)' : item.title,
                    style: const TextStyle(fontSize: 15, color: AppColors.text),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    item.key,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.text),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Remove',
                  onPressed: () => unawaited(_removeSongItem(index)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServicePeriodBar extends StatelessWidget {
  final ServicePeriod selected;
  final ValueChanged<ServicePeriod> onChanged;
  final Color accentColor;

  const _ServicePeriodBar({
    required this.selected,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: AppColors.borderSide),
      ),
      child: Row(
        children: ServicePeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(period),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  border: period == ServicePeriod.am
                      ? const Border(right: AppColors.borderSide)
                      : null,
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    period.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateNavBar extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onDateTap;
  final Color accentColor;

  const _DateNavBar({
    required this.dateLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onDateTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: AppColors.borderSide),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPrevious,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(right: AppColors.borderSide),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Prev',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onDateTap,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(right: AppColors.borderSide),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onNext,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Next',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
