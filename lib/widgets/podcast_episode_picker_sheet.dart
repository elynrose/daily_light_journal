import 'dart:async';

import 'package:flutter/material.dart';

import '../models/podcast_feed_item.dart';
import '../services/app_preferences_service.dart';
import '../services/feed_pin_session.dart';
import '../services/rss_feed_service.dart';
import '../theme/app_colors.dart';
import 'feed_pin_dialog.dart';

Future<PodcastFeedItem?> showPodcastEpisodePicker(BuildContext context) {
  return showModalBottomSheet<PodcastFeedItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.offWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _PodcastEpisodePickerSheet(),
  );
}

class _PodcastEpisodePickerSheet extends StatefulWidget {
  const _PodcastEpisodePickerSheet();

  @override
  State<_PodcastEpisodePickerSheet> createState() =>
      _PodcastEpisodePickerSheetState();
}

class _PodcastEpisodePickerSheetState extends State<_PodcastEpisodePickerSheet> {
  final _feedService = RssFeedService.instance;
  final _searchController = TextEditingController();

  List<PodcastFeedItem> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFeed());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PodcastFeedItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) => item.matchesFilter(query: query)).toList();
  }

  Future<void> _loadFeed() async {
    final feedUrls = AppPreferencesService.instance.prefs.podcastFeedUrls;
    if (feedUrls.isEmpty) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _errorMessage = 'Add podcast feed URLs in Settings';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final mergedItems = <PodcastFeedItem>[];
    final warnings = <String>[];

    await Future.wait(
      feedUrls.map((feedUrl) async {
        try {
          final feed = await _feedService.fetchFeed(feedUrl);
          for (final item in feed.items) {
            mergedItems.add(
              item.withSource(
                sourceFeedUrl: feedUrl,
                channelTitle: feed.channelTitle,
                feedPin: feed.pin,
              ),
            );
          }
        } catch (_) {
          warnings.add('Could not load $feedUrl');
        }
      }),
    );

    if (!mounted) return;

    mergedItems.sort((a, b) {
      final aDate = a.pubDate;
      final bDate = b.pubDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    setState(() {
      _items = mergedItems;
      _isLoading = false;
      if (mergedItems.isEmpty && warnings.isNotEmpty) {
        _errorMessage = warnings.join('\n');
      }
    });
  }

  Future<void> _selectItem(PodcastFeedItem item) async {
    final feedUrl = item.sourceFeedUrl;
    final requiredPin = item.effectivePin();

    if (requiredPin != null && feedUrl.isNotEmpty) {
      if (!FeedPinSession.instance.isVerified(feedUrl, requiredPin)) {
        final enteredPin = await showFeedPinDialog(context);
        if (!mounted || enteredPin == null) return;
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
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select podcast episode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.text),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search episodes',
                  isDense: true,
                  border: AppColors.outlineInputBorder,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ),
                ),
              )
            else if (_filteredItems.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No episodes found',
                    style: TextStyle(color: AppColors.text),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, __) => AppColors.listSeparator(),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.title.isEmpty ? '(Untitled)' : item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.text,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (item.author.isNotEmpty) item.author,
                          if (item.displayDateLabel != null) item.displayDateLabel!,
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12, color: AppColors.text),
                      ),
                      onTap: () => unawaited(_selectItem(item)),
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
