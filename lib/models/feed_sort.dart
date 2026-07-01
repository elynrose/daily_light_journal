import 'podcast_feed_item.dart';

enum FeedSortOption {
  publishedNewest,
  publishedOldest,
  titleAz,
  titleZa,
  authorAz,
  categoryAz,
}

extension FeedSortOptionLabel on FeedSortOption {
  String get label {
    switch (this) {
      case FeedSortOption.publishedNewest:
        return 'Published (newest)';
      case FeedSortOption.publishedOldest:
        return 'Published (oldest)';
      case FeedSortOption.titleAz:
        return 'Title (A–Z)';
      case FeedSortOption.titleZa:
        return 'Title (Z–A)';
      case FeedSortOption.authorAz:
        return 'Author (A–Z)';
      case FeedSortOption.categoryAz:
        return 'Category (A–Z)';
    }
  }

  static FeedSortOption fromFeedFields({
    String? orderBy,
    String? orderDirection,
  }) {
    final field = orderBy?.trim().toLowerCase() ?? '';
    final descending = _isDescending(orderDirection);

    switch (field) {
      case 'pubdate':
      case 'pub_date':
      case 'published':
      case 'date':
        return descending
            ? FeedSortOption.publishedNewest
            : FeedSortOption.publishedOldest;
      case 'title':
        return descending ? FeedSortOption.titleZa : FeedSortOption.titleAz;
      case 'author':
        return FeedSortOption.authorAz;
      case 'category':
        return FeedSortOption.categoryAz;
      default:
        return FeedSortOption.publishedNewest;
    }
  }

  static bool _isDescending(String? orderDirection) {
    final value = orderDirection?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return true;
    }
    return value == 'desc' || value == 'descending' || value == 'newest';
  }
}

List<PodcastFeedItem> sortFeedItems(
  List<PodcastFeedItem> items,
  FeedSortOption sortOption,
) {
  final sorted = List<PodcastFeedItem>.from(items);
  sorted.sort((a, b) {
    final comparison = switch (sortOption) {
      FeedSortOption.publishedNewest ||
      FeedSortOption.publishedOldest =>
        _compareDates(a.pubDate, b.pubDate),
      FeedSortOption.titleAz || FeedSortOption.titleZa =>
        _compareText(a.title, b.title),
      FeedSortOption.authorAz => _compareText(a.author, b.author),
      FeedSortOption.categoryAz =>
        _compareText(a.category ?? '', b.category ?? ''),
    };

    if (comparison != 0) {
      return _applyDirection(comparison, sortOption);
    }

    return _compareText(a.title, b.title);
  });
  return sorted;
}

bool _isDescendingOption(FeedSortOption sortOption) {
  return switch (sortOption) {
    FeedSortOption.publishedNewest || FeedSortOption.titleZa => true,
    FeedSortOption.publishedOldest ||
    FeedSortOption.titleAz ||
    FeedSortOption.authorAz ||
    FeedSortOption.categoryAz =>
      false,
  };
}

int _applyDirection(int comparison, FeedSortOption sortOption) {
  return _isDescendingOption(sortOption) ? -comparison : comparison;
}

int _compareDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}

int _compareText(String a, String b) {
  return a.toLowerCase().compareTo(b.toLowerCase());
}
