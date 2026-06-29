import 'sermon_feed_item.dart';

enum FeedSortOption {
  datePreachedNewest,
  datePreachedOldest,
  publishedNewest,
  publishedOldest,
  titleAz,
  titleZa,
  preacherAz,
  categoryAz,
}

extension FeedSortOptionLabel on FeedSortOption {
  String get label {
    switch (this) {
      case FeedSortOption.datePreachedNewest:
        return 'Date preached (newest)';
      case FeedSortOption.datePreachedOldest:
        return 'Date preached (oldest)';
      case FeedSortOption.publishedNewest:
        return 'Published (newest)';
      case FeedSortOption.publishedOldest:
        return 'Published (oldest)';
      case FeedSortOption.titleAz:
        return 'Title (A–Z)';
      case FeedSortOption.titleZa:
        return 'Title (Z–A)';
      case FeedSortOption.preacherAz:
        return 'Preacher (A–Z)';
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
      case 'date_preached':
      case 'date':
        return descending
            ? FeedSortOption.datePreachedNewest
            : FeedSortOption.datePreachedOldest;
      case 'published_date':
      case 'published':
      case 'pubdate':
        return descending
            ? FeedSortOption.publishedNewest
            : FeedSortOption.publishedOldest;
      case 'sermon_title':
      case 'title':
        return descending ? FeedSortOption.titleZa : FeedSortOption.titleAz;
      case 'preached_by':
      case 'preacher':
      case 'author':
        return FeedSortOption.preacherAz;
      case 'category':
        return FeedSortOption.categoryAz;
      default:
        return FeedSortOption.datePreachedNewest;
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

List<SermonFeedItem> sortFeedItems(
  List<SermonFeedItem> items,
  FeedSortOption sortOption,
) {
  final sorted = List<SermonFeedItem>.from(items);
  sorted.sort((a, b) {
    final comparison = switch (sortOption) {
      FeedSortOption.datePreachedNewest ||
      FeedSortOption.datePreachedOldest =>
        _compareDates(a.datePreached, b.datePreached),
      FeedSortOption.publishedNewest ||
      FeedSortOption.publishedOldest =>
        _compareDates(a.publishedDate, b.publishedDate),
      FeedSortOption.titleAz || FeedSortOption.titleZa =>
        _compareText(a.sermonTitle, b.sermonTitle),
      FeedSortOption.preacherAz =>
        _compareText(a.preachedBy, b.preachedBy),
      FeedSortOption.categoryAz =>
        _compareText(a.category ?? '', b.category ?? ''),
    };

    if (comparison != 0) {
      return _applyDirection(comparison, sortOption);
    }

    return _compareText(a.sermonTitle, b.sermonTitle);
  });
  return sorted;
}

bool _isDescendingOption(FeedSortOption sortOption) {
  return switch (sortOption) {
    FeedSortOption.datePreachedNewest ||
    FeedSortOption.publishedNewest ||
    FeedSortOption.titleZa =>
      true,
    FeedSortOption.datePreachedOldest ||
    FeedSortOption.publishedOldest ||
    FeedSortOption.titleAz ||
    FeedSortOption.preacherAz ||
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
