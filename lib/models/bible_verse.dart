class BibleVerse {
  final String reference;
  final String text;

  const BibleVerse({
    required this.reference,
    required this.text,
  });

  static String chapterKeyFromReference(String reference) {
    final colonIndex = reference.lastIndexOf(':');
    if (colonIndex <= 0) return reference;
    return reference.substring(0, colonIndex);
  }

  String get chapterKey => chapterKeyFromReference(reference);

  String toNotesLine() => '$reference\n$text';

  String toNotificationBody({int maxTextLength = 200}) {
    final excerpt = _truncate(text, maxTextLength);
    return '$reference\n$excerpt';
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength).trimRight()}…';
  }
}