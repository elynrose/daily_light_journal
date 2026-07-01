class Song {
  final String id;
  final String title;
  final String key;
  final String lyrics;
  final String number;

  const Song({
    required this.id,
    required this.title,
    required this.key,
    required this.lyrics,
    this.number = '',
  });

  Song copyWith({
    String? id,
    String? title,
    String? key,
    String? lyrics,
    String? number,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      key: key ?? this.key,
      lyrics: lyrics ?? this.lyrics,
      number: number ?? this.number,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'key': key,
      'lyrics': lyrics,
      'number': number,
    };
  }

  factory Song.fromMap(Map<dynamic, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      key: map['key'] as String? ?? '',
      lyrics: map['lyrics'] as String? ?? '',
      number: map['number'] as String? ?? '',
    );
  }

  factory Song.fromJson(Map<String, dynamic> json, {String? id}) {
    final number = json['number'] as String? ?? '';
    return Song(
      id: id ?? 'song-$number',
      title: json['title'] as String? ?? '',
      key: json['key'] as String? ?? '',
      lyrics: json['lyrics'] as String? ?? '',
      number: number,
    );
  }
}
