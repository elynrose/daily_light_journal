class JournalSongItem {
  final String title;
  final String key;

  const JournalSongItem({
    required this.title,
    this.key = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'key': key,
    };
  }

  factory JournalSongItem.fromMap(Map<dynamic, dynamic> map) {
    return JournalSongItem(
      title: map['title'] as String? ?? '',
      key: map['key'] as String? ?? '',
    );
  }
}
