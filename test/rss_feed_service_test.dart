import 'package:church_journal/models/feed_sort.dart';
import 'package:church_journal/models/podcast_feed_item.dart';
import 'package:church_journal/services/feed_pin_session.dart';
import 'package:church_journal/services/rss_feed_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = RssFeedService.instance;

  setUp(FeedPinSession.instance.clearAll);

  test('parses standard podcast RSS fields', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <pin>2468</pin>
    <order_by>title</order_by>
    <order_direction>asc</order_direction>
    <language>en-us</language>
    <itunes:author>Grace Community</itunes:author>
    <item>
      <title>Walking in Faith</title>
      <itunes:author>Pastor John</itunes:author>
      <pubDate>Sat, 15 Jun 2024 18:00:00 GMT</pubDate>
      <enclosure url="https://example.com/sermon.mp3" type="audio/mpeg"/>
      <itunes:image href="https://example.com/cover.jpg"/>
      <category>Sunday Sermon</category>
      <guid>episode-1</guid>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.channelTitle, isNull);
    expect(feed.pin, '2468');
    expect(feed.sortOption, FeedSortOption.titleAz);
    expect(feed.items, hasLength(1));
    expect(feed.items.first.title, 'Walking in Faith');
    expect(feed.items.first.author, 'Pastor John');
    expect(feed.items.first.enclosureUrl, 'https://example.com/sermon.mp3');
    expect(feed.items.first.pubDate, DateTime.utc(2024, 6, 15, 18));
    expect(feed.items.first.imageUrl, 'https://example.com/cover.jpg');
    expect(feed.items.first.category, 'Sunday Sermon');
    expect(feed.items.first.language, 'en-us');
    expect(feed.items.first.guid, 'episode-1');
    expect(feed.items.first.effectivePin(), '2468');
  });

  test('parses item-level pin override', () {
    const xml = '''
<rss>
  <channel>
    <pin>1111</pin>
    <item>
      <title>Special Episode</title>
      <author>Pastor Lee</author>
      <enclosure url="https://example.com/special.mp3" type="audio/mpeg"/>
      <pin>9999</pin>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.pin, '1111');
    expect(feed.items.first.pin, '9999');
    expect(feed.items.first.effectivePin(), '9999');
  });

  test('parses enclosure and RFC 822 pubDate', () {
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
    expect(feed.items.first.title, 'Sunday Message');
    expect(feed.items.first.author, 'Rev. Smith');
    expect(feed.items.first.enclosureUrl, 'https://example.com/audio.mp3');
    expect(feed.items.first.pubDate, DateTime.utc(2024, 6, 16, 12));
  });

  test('uses channel author when item has no author', () {
    const xml = '''
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <itunes:author>Church Media Team</itunes:author>
    <item>
      <title>Weekly Update</title>
      <enclosure url="https://example.com/update.mp3" type="audio/mpeg"/>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.items.first.author, 'Church Media Team');
  });

  test('filters items by search query and language', () {
    final item = PodcastFeedItem(
      title: 'Hope in Christ',
      author: 'Pastor Ana',
      enclosureUrl: 'https://example.com/hope.mp3',
      language: 'Spanish',
      category: 'Bible Study',
      pubDate: DateTime(2024, 3, 10),
      sourceFeedUrl: 'https://example.com/feed.xml',
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
      item.matchesFilter(
        query: 'hope',
        language: 'Spanish',
        category: 'Bible Study',
        sourceFeedUrl: 'https://example.com/feed.xml',
      ),
      isTrue,
    );
    expect(
      item.matchesFilter(
        query: '',
        sourceFeedUrl: 'https://other.example/feed.xml',
      ),
      isFalse,
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
      PodcastFeedItem(
        title: 'Zion',
        author: 'Pastor A',
        enclosureUrl: 'https://example.com/z.mp3',
        pubDate: DateTime(2024, 1, 1),
      ),
      PodcastFeedItem(
        title: 'Alpha',
        author: 'Pastor B',
        enclosureUrl: 'https://example.com/a.mp3',
        pubDate: DateTime(2024, 6, 1),
      ),
    ];

    final newest = sortFeedItems(items, FeedSortOption.publishedNewest);
    expect(newest.first.title, 'Alpha');

    final titleAz = sortFeedItems(items, FeedSortOption.titleAz);
    expect(titleAz.first.title, 'Alpha');
  });

  test('skips items missing required fields', () {
    const xml = '''
<rss>
  <channel>
    <item>
      <title>Missing Audio</title>
      <author>Someone</author>
    </item>
    <item>
      <enclosure url="https://example.com/a.mp3" type="audio/mpeg"/>
    </item>
  </channel>
</rss>
''';

    final feed = service.parseFeedXml(xml);
    expect(feed.items, isEmpty);
  });
}
