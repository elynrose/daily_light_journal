import 'feed_sort.dart';
import 'sermon_feed_item.dart';

class SermonFeedData {
  final String? pin;
  final FeedSortOption sortOption;
  final List<SermonFeedItem> items;

  const SermonFeedData({
    required this.items,
    this.pin,
    this.sortOption = FeedSortOption.datePreachedNewest,
  });
}
