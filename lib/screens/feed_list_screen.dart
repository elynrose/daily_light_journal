import 'dart:async';

import 'package:flutter/material.dart';

import '../models/feed_sort.dart';
import '../models/podcast_feed_item.dart';
import '../services/app_preferences_service.dart';
import '../services/feed_pin_session.dart';
import '../services/rss_feed_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feed_pin_dialog.dart';
import 'sermon_player_screen.dart';

class FeedListScreen extends StatefulWidget {
  const FeedListScreen({super.key});

  @override
  State<FeedListScreen> createState() => _FeedListScreenState();
}

class _FeedListScreenState extends State<FeedListScreen> {
  final _feedService = RssFeedService.instance;
  final _prefsService = AppPreferencesService.instance;
  final _searchController = TextEditingController();

  List<PodcastFeedItem> _items = const [];
  String? _feedPin;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedLanguage;
  String? _selectedCategory;
  FeedSortOption _sortOption = FeedSortOption.publishedNewest;

  @override
  void initState() {
    super.initState();
    _prefsService.addListener(_onPrefsChanged);
    unawaited(_loadFeed());
  }

  @override
  void dispose() {
    _prefsService.removeListener(_onPrefsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    FeedPinSession.instance.clearAll();
    unawaited(_loadFeed());
  }

  List<String> _uniqueValues(String? Function(PodcastFeedItem item) pick) {
    final values = <String>{};
    for (final item in _items) {
      final value = pick(item)?.trim();
      if (value != null && value.isNotEmpty) {
        values.add(value);
      }
    }
    final sorted = values.toList()..sort();
    return sorted;
  }

  List<String> get _availableLanguages =>
      _uniqueValues((item) => item.language);

  List<String> get _availableCategories =>
      _uniqueValues((item) => item.category);

  List<PodcastFeedItem> get _filteredItems {
    final query = _searchController.text;
    final filtered = _items
        .where(
          (item) => item.matchesFilter(
            query: query,
            language: _selectedLanguage,
            category: _selectedCategory,
          ),
        )
        .toList();
    return sortFeedItems(filtered, _sortOption);
  }

  Future<void> _loadFeed() async {
    final feedUrl = _prefsService.prefs.sermonFeedUrl.trim();
    if (feedUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _feedPin = null;
        _errorMessage = null;
        _isLoading = false;
        _selectedLanguage = null;
        _selectedCategory = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feed = await _feedService.fetchFeed(feedUrl);
      if (!mounted) return;

      final previousPin = _feedPin;
      final nextPin = feed.pin?.trim();
      if (previousPin != null &&
          nextPin != null &&
          previousPin != nextPin) {
        FeedPinSession.instance.clearForFeed(feedUrl);
      }

      setState(() {
        _items = feed.items;
        _feedPin = nextPin;
        _sortOption = feed.sortOption;
        _isLoading = false;
        if (_selectedLanguage != null &&
            !_availableLanguages.contains(_selectedLanguage)) {
          _selectedLanguage = null;
        }
        if (_selectedCategory != null &&
            !_availableCategories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _feedPin = null;
        _errorMessage = '$error';
        _isLoading = false;
        _selectedLanguage = null;
        _selectedCategory = null;
      });
    }
  }

  Future<void> _openPlayer(PodcastFeedItem item) async {
    final feedUrl = _prefsService.prefs.sermonFeedUrl.trim();
    final requiredPin = item.effectivePin(_feedPin);

    if (requiredPin != null) {
      if (!FeedPinSession.instance.isVerified(feedUrl, requiredPin)) {
        final enteredPin = await showFeedPinDialog(context);
        if (!mounted || enteredPin == null) {
          return;
        }
        if (enteredPin != requiredPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN')),
          );
          return;
        }
        FeedPinSession.instance.markVerified(feedUrl, requiredPin);
      }
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SermonPlayerScreen(item: item),
      ),
    );
  }

  void _onSearchChanged(String _) {
    setState(() {});
  }

  void _selectLanguage(String? language) {
    setState(() => _selectedLanguage = language);
  }

  void _selectCategory(String? category) {
    setState(() => _selectedCategory = category);
  }

  void _selectSortOption(FeedSortOption? sortOption) {
    if (sortOption == null) return;
    setState(() => _sortOption = sortOption);
  }

  Widget _buildSortSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          const Text(
            'Order by',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<FeedSortOption>(
                    isExpanded: true,
                    value: _sortOption,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                    dropdownColor: Colors.white,
                    items: FeedSortOption.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: _selectSortOption,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FeedFilterChip(
                  label: 'All',
                  selected: selected == null,
                  onTap: () => onSelected(null),
                ),
                for (final option in options) ...[
                  const SizedBox(width: 8),
                  _FeedFilterChip(
                    label: option,
                    selected: selected == option,
                    onTap: () => onSelected(option),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search episodes',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: AppColors.text),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear, color: AppColors.text),
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: AppColors.outlineInputBorder,
          enabledBorder: AppColors.outlineInputBorder,
          focusedBorder: AppColors.outlineInputBorder,
        ),
        style: const TextStyle(color: AppColors.text),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildLanguageFilters() {
    return _buildFilterRow(
      title: 'Language',
      options: _availableLanguages,
      selected: _selectedLanguage,
      onSelected: _selectLanguage,
    );
  }

  Widget _buildCategoryFilters() {
    return _buildFilterRow(
      title: 'Category',
      options: _availableCategories,
      selected: _selectedCategory,
      onSelected: _selectCategory,
    );
  }

  Widget _buildEpisodeList(List<PodcastFeedItem> items) {
    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => AppColors.listSeparator(),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => unawaited(_openPlayer(item)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeedCoverThumbnail(coverUrl: item.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        if (item.author.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.author,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                        if (item.displayDateLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.displayDateLabel!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                        if (item.category != null &&
                            item.category!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.category!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                        if (item.language != null &&
                            item.language!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.language!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_outline, color: AppColors.text),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedUrl = _prefsService.prefs.sermonFeedUrl.trim();

    if (feedUrl.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Add a podcast feed URL in Settings to load episodes here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text, fontSize: 15),
          ),
        ),
      );
    }

    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => unawaited(_loadFeed()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No episodes found in this podcast.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => unawaited(_loadFeed()),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredItems = _filteredItems;
    final hasActiveFilter = _searchController.text.trim().isNotEmpty ||
        _selectedLanguage != null ||
        _selectedCategory != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        _buildSortSelector(),
        _buildCategoryFilters(),
        _buildLanguageFilters(),
        if (_isLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: filteredItems.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadFeed,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.25,
                      ),
                      Text(
                        hasActiveFilter
                            ? 'No episodes match your search.'
                            : 'No sermons found in this feed.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.text),
                      ),
                    ],
                  ),
                )
              : _buildEpisodeList(filteredItems),
        ),
      ],
    );
  }
}

class _FeedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FeedFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: AppColors.text,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppColors.dustyBlue,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class _FeedCoverThumbnail extends StatelessWidget {
  final String? coverUrl;

  const _FeedCoverThumbnail({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: coverUrl != null && coverUrl!.isNotEmpty
            ? Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Colors.white,
      child: Center(
        child: Icon(Icons.podcasts, color: AppColors.text, size: 28),
      ),
    );
  }
}
