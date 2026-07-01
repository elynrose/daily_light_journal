import 'feed_sort.dart';
import 'podcast_feed_item.dart';

class PodcastFeedData {
  final String? channelTitle;
  final String? pin;
  final FeedSortOption sortOption;
  final List<PodcastFeedItem> items;

  const PodcastFeedData({
    required this.items,
    this.channelTitle,
    this.pin,
    this.sortOption = FeedSortOption.publishedNewest,
  });
}
