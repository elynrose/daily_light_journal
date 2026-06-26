import 'entry.dart';

class JournalPhoto {
  final String id;
  final String fileName;
  final DateTime capturedAt;
  final DateTime? journalDate;
  final ServicePeriod? journalPeriod;

  const JournalPhoto({
    required this.id,
    required this.fileName,
    required this.capturedAt,
    this.journalDate,
    this.journalPeriod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'capturedAt': capturedAt.toIso8601String(),
      if (journalDate != null) 'journalDate': journalDate!.toIso8601String(),
      if (journalPeriod != null) 'journalPeriod': journalPeriod!.index,
    };
  }

  factory JournalPhoto.fromMap(Map<String, dynamic> map) {
    return JournalPhoto(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      capturedAt: DateTime.parse(map['capturedAt'] as String),
      journalDate: map['journalDate'] != null
          ? DateTime.parse(map['journalDate'] as String)
          : null,
      journalPeriod: map['journalPeriod'] != null
          ? ServicePeriod.values[map['journalPeriod'] as int]
          : null,
    );
  }

  String get journalLabel {
    if (journalDate == null) return '';
    final date =
        '${journalDate!.month}/${journalDate!.day}/${journalDate!.year}';
    if (journalPeriod == null) return date;
    return '$date · ${journalPeriod!.label}';
  }
}
