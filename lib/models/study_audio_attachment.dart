import 'podcast_feed_item.dart';

class StudyAudioAttachment {
  final String title;
  final String enclosureUrl;
  final String author;
  final String sourceFeedUrl;
  final String? channelTitle;
  final String? imageUrl;

  const StudyAudioAttachment({
    required this.title,
    required this.enclosureUrl,
    this.author = '',
    this.sourceFeedUrl = '',
    this.channelTitle,
    this.imageUrl,
  });

  factory StudyAudioAttachment.fromMap(Map<dynamic, dynamic> map) {
    return StudyAudioAttachment(
      title: map['title'] as String? ?? '',
      enclosureUrl: map['enclosureUrl'] as String? ?? '',
      author: map['author'] as String? ?? '',
      sourceFeedUrl: map['sourceFeedUrl'] as String? ?? '',
      channelTitle: map['channelTitle'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'enclosureUrl': enclosureUrl,
      'author': author,
      'sourceFeedUrl': sourceFeedUrl,
      'channelTitle': channelTitle,
      'imageUrl': imageUrl,
    };
  }

  factory StudyAudioAttachment.fromPodcastItem(PodcastFeedItem item) {
    return StudyAudioAttachment(
      title: item.title,
      enclosureUrl: item.enclosureUrl,
      author: item.author,
      sourceFeedUrl: item.sourceFeedUrl,
      channelTitle: item.channelTitle,
      imageUrl: item.imageUrl,
    );
  }

  PodcastFeedItem toPodcastItem() {
    return PodcastFeedItem(
      title: title,
      author: author,
      enclosureUrl: enclosureUrl,
      imageUrl: imageUrl,
      sourceFeedUrl: sourceFeedUrl,
      channelTitle: channelTitle,
    );
  }
}
