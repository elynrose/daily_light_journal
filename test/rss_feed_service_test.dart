import 'package:church_journal/models/feed_sort.dart';
import 'package:church_journal/models/sermon_feed_item.dart';
import 'package:church_journal/services/feed_pin_session.dart';
import 'package:church_journal/services/rss_feed_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = RssFeedService.instance;

  setUp(FeedPinSession.instance.clearAll);

  test('parses custom sermon RSS fields', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <pin>2468</pin>
    <order_by>sermon_title</order_by>
    <order_direction>asc</order_direction>
    <item>
      <sermon_title>Walking in Faith</sermon_title>
      <preached_by>Pastor John</preached_by>
      <audio_url>https://example.com/sermon.mp3</audio_url>
      <category>Sunday Sermon</category>
      <date_preached>2024-06-15</date_preached>
      <cover_image>https://example.com/cover.jpg</cover_image>
      <language>English</language>
      <published_date>2024-06-16T10:00:00Z</published_date>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.pin, '2468');
    expect(feed.sortOption, FeedSortOption.titleAz);
    expect(feed.items, hasLength(1));
    expect(feed.items.first.sermonTitle, 'Walking in Faith');
    expect(feed.items.first.preachedBy, 'Pastor John');
    expect(feed.items.first.audioUrl, 'https://example.com/sermon.mp3');
    expect(feed.items.first.datePreached, DateTime.parse('2024-06-15'));
    expect(feed.items.first.coverImage, 'https://example.com/cover.jpg');
    expect(feed.items.first.category, 'Sunday Sermon');
    expect(feed.items.first.language, 'English');
    expect(feed.items.first.publishedDate, DateTime.parse('2024-06-16T10:00:00Z'));
    expect(feed.items.first.effectivePin(feed.pin), '2468');
  });

  test('parses item-level pin override', () {
    const xml = '''
<rss>
  <channel>
    <pin>1111</pin>
    <item>
      <sermon_title>Special Sermon</sermon_title>
      <preached_by>Pastor Lee</preached_by>
      <audio_url>https://example.com/special.mp3</audio_url>
      <pin>9999</pin>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.pin, '1111');
    expect(feed.items.first.pin, '9999');
    expect(feed.items.first.effectivePin(feed.pin), '9999');
  });

  test('parses standard podcast RSS with enclosure', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Sunday Message</title>
      <author>Rev. Smith</author>
      <pubDate>Sun, 16 Jun 2024 12:00:00 GMT</pubDate>
      <enclosure url="https://example.com/audio.mp3" type="audio/mpeg"/>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.items, hasLength(1));
    expect(feed.items.first.sermonTitle, 'Sunday Message');
    expect(feed.items.first.preachedBy, 'Rev. Smith');
    expect(feed.items.first.audioUrl, 'https://example.com/audio.mp3');
  });

  test('filters items by search query and language', () {
    final item = SermonFeedItem(
      sermonTitle: 'Hope in Christ',
      preachedBy: 'Pastor Ana',
      audioUrl: 'https://example.com/hope.mp3',
      language: 'Spanish',
      category: 'Bible Study',
      datePreached: DateTime(2024, 3, 10),
    );

    expect(item.matchesFilter(query: 'hope', language: null), isTrue);
    expect(item.matchesFilter(query: 'bible study', language: null), isTrue);
    expect(item.matchesFilter(query: 'pastor ana', language: null), isTrue);
    expect(item.matchesFilter(query: 'spanish', language: null), isTrue);
    expect(item.matchesFilter(query: '2024', language: null), isTrue);
    expect(item.matchesFilter(query: 'missing', language: null), isFalse);
    expect(item.matchesFilter(query: '', language: 'Spanish'), isTrue);
    expect(item.matchesFilter(query: '', language: 'English'), isFalse);
    expect(item.matchesFilter(query: 'hope', language: 'Spanish'), isTrue);
    expect(item.matchesFilter(query: 'hope', language: 'English'), isFalse);
    expect(item.matchesFilter(query: '', category: 'Bible Study'), isTrue);
    expect(item.matchesFilter(query: '', category: 'Sunday Sermon'), isFalse);
    expect(
      item.matchesFilter(query: 'hope', language: 'Spanish', category: 'Bible Study'),
      isTrue,
    );
  });

  test('feed pin session remembers verified pin per feed', () {
    const feedUrl = 'https://example.com/feed.xml';
    const pin = '4321';

    expect(FeedPinSession.instance.isVerified(feedUrl, pin), isFalse);
    FeedPinSession.instance.markVerified(feedUrl, pin);
    expect(FeedPinSession.instance.isVerified(feedUrl, pin), isTrue);
    expect(FeedPinSession.instance.isVerified(feedUrl, '9999'), isFalse);
  });

  test('sorts feed items by selected option', () {
    final items = [
      SermonFeedItem(
        sermonTitle: 'Zion',
        preachedBy: 'Pastor A',
        audioUrl: 'https://example.com/z.mp3',
        datePreached: DateTime(2024, 1, 1),
      ),
      SermonFeedItem(
        sermonTitle: 'Alpha',
        preachedBy: 'Pastor B',
        audioUrl: 'https://example.com/a.mp3',
        datePreached: DateTime(2024, 6, 1),
      ),
    ];

    final newest = sortFeedItems(items, FeedSortOption.datePreachedNewest);
    expect(newest.first.sermonTitle, 'Alpha');

    final titleAz = sortFeedItems(items, FeedSortOption.titleAz);
    expect(titleAz.first.sermonTitle, 'Alpha');
  });

  test('skips items missing required fields', () {
    const xml = '''
<rss>
  <channel>
    <item>
      <sermon_title>Missing Audio</sermon_title>
      <preached_by>Someone</preached_by>
    </item>
    <item>
      <title>Missing Preacher</title>
      <audio_url>https://example.com/a.mp3</audio_url>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.items, isEmpty);
  });
}
