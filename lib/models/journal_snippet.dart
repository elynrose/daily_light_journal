import 'entry.dart';

class JournalSnippet {
  final DateTime date;
  final ServicePeriod period;
  final EntryCategory category;
  final String title;
  final String preachedBy;
  final String note;

  const JournalSnippet({
    required this.date,
    required this.period,
    required this.category,
    required this.title,
    required this.preachedBy,
    required this.note,
  });

  String formatDate() {
    final d = date;
    return '${d.month}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  String toNotificationBody({int maxNoteLength = 200}) {
    final excerpt = _truncate(note, maxNoteLength);
    final lines = <String>[
      '${formatDate()} · ${period.label}',
      if (title.isNotEmpty) title,
      if (preachedBy.isNotEmpty) 'Preached by: $preachedBy',
      excerpt,
    ];
    return lines.join('\n');
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }
}
