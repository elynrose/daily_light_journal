class MoodOption {
  final String name;
  final String emoji;

  const MoodOption({
    required this.name,
    required this.emoji,
  });
}

class MoodScripture {
  final String moodName;
  final String emoji;
  final String scripture;
  final String scriptureText;

  const MoodScripture({
    required this.moodName,
    required this.emoji,
    required this.scripture,
    required this.scriptureText,
  });

  factory MoodScripture.fromMap(Map<String, dynamic> map) {
    return MoodScripture(
      moodName: map['mood_name'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '',
      scripture: map['scripture'] as String? ?? '',
      scriptureText: map['scripture_text'] as String? ?? '',
    );
  }

  String toNotificationBody({int maxTextLength = 200}) {
    final excerpt = _truncate(scriptureText, maxTextLength);
    return '$scripture\n$excerpt';
  }

  String get notificationTitle => '$emoji $moodName';

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength).trimRight()}…';
  }
}
