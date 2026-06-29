class SermonFeedItem {
  final String sermonTitle;
  final String preachedBy;
  final String audioUrl;
  final DateTime? datePreached;
  final String? coverImage;
  final String? language;
  final String? category;
  final DateTime? publishedDate;
  final String? id;
  final String? pin;

  const SermonFeedItem({
    required this.sermonTitle,
    required this.preachedBy,
    required this.audioUrl,
    this.datePreached,
    this.coverImage,
    this.language,
    this.category,
    this.publishedDate,
    this.id,
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
    final date = datePreached ?? publishedDate;
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
      sermonTitle,
      preachedBy,
      this.language ?? '',
      this.category ?? '',
      displayDateLabel ?? '',
      if (datePreached != null) datePreached!.toIso8601String(),
      if (publishedDate != null) publishedDate!.toIso8601String(),
    ].join(' ').toLowerCase();

    return searchable.contains(trimmed);
  }
}
