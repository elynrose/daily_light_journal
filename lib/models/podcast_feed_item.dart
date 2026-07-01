class PodcastFeedItem {
  final String title;
  final String author;
  final String enclosureUrl;
  final DateTime? pubDate;
  final String? imageUrl;
  final String? language;
  final String? category;
  final String? guid;
  final String? pin;

  const PodcastFeedItem({
    required this.title,
    required this.author,
    required this.enclosureUrl,
    this.pubDate,
    this.imageUrl,
    this.language,
    this.category,
    this.guid,
    this.pin,
  });

  String? effectivePin(String? feedPin) {
    final itemPin = pin?.trim();
    if (itemPin != null && itemPin.isNotEmpty) {
      return itemPin;
    }
    final channelPin = feedPin?.trim();
    if (channelPin != null && channelPin.isNotEmpty) {
      return channelPin;
    }
    return null;
  }

  String? get displayDateLabel {
    final date = pubDate;
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  bool matchesFilter({
    required String query,
    String? language,
    String? category,
  }) {
    if (language != null && language.isNotEmpty) {
      final itemLanguage = (this.language ?? '').trim().toLowerCase();
      if (itemLanguage != language.trim().toLowerCase()) {
        return false;
      }
    }

    if (category != null && category.isNotEmpty) {
      final itemCategory = (this.category ?? '').trim().toLowerCase();
      if (itemCategory != category.trim().toLowerCase()) {
        return false;
      }
    }

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return true;
    }

    final searchable = [
      title,
      author,
      this.language ?? '',
      this.category ?? '',
      displayDateLabel ?? '',
      if (pubDate != null) pubDate!.toIso8601String(),
    ].join(' ').toLowerCase();

    return searchable.contains(trimmed);
  }
}
