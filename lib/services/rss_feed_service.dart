import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/feed_sort.dart';
import '../models/podcast_feed_data.dart';
import '../models/podcast_feed_item.dart';

class RssFeedService {
  RssFeedService._();

  static final RssFeedService instance = RssFeedService._();

  static const _audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.ogg',
    '.wav',
    '.flac',
    '.opus',
  };

  static const _monthNames = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  Future<PodcastFeedData> fetchFeed(String feedUrl) async {
    final trimmed = feedUrl.trim();
    if (trimmed.isEmpty) {
      return const PodcastFeedData(items: []);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      throw FormatException('Enter a valid feed URL (https://...)');
    }

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException('Feed request failed (${response.statusCode})');
    }

    return parseFeedXml(response.body);
  }

  PodcastFeedData parseFeedXml(String xmlBody) {
    final document = XmlDocument.parse(xmlBody);
    final channel = _findChannel(document);
    final feedPin = channel == null ? null : _childText(channel, {'pin'});
    final sortOption = FeedSortOptionLabel.fromFeedFields(
      orderBy: channel == null ? null : _childText(channel, {'order_by'}),
      orderDirection:
          channel == null ? null : _childText(channel, {'order_direction'}),
    );
    final channelAuthor = channel == null
        ? null
        : _firstNonEmpty([
            _childText(channel, {'author'}),
            _childText(channel, {'itunes:author'}),
          ]);
    final channelLanguage = channel == null
        ? null
        : _childText(channel, {'language'});
    final channelImage = channel == null
        ? null
        : _firstNonEmpty([
            _attributeValue(channel, 'image', 'href'),
            _attributeValue(channel, 'itunes:image', 'href'),
            _childText(channel, {'image'}),
          ]);

    final items = <PodcastFeedItem>[];

    for (final element in document.descendants.whereType<XmlElement>()) {
      final localName = element.localName.toLowerCase();
      if (localName != 'item' && localName != 'entry') {
        continue;
      }

      final parsed = _parseFeedElement(
        element,
        channelAuthor: channelAuthor,
        channelLanguage: channelLanguage,
        channelImage: channelImage,
      );
      if (parsed != null) {
        items.add(parsed);
      }
    }

    return PodcastFeedData(
      pin: feedPin,
      sortOption: sortOption,
      items: sortFeedItems(items, sortOption),
    );
  }

  XmlElement? _findChannel(XmlDocument document) {
    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.localName.toLowerCase() == 'channel') {
        return element;
      }
    }
    return null;
  }

  PodcastFeedItem? _parseFeedElement(
    XmlElement element, {
    String? channelAuthor,
    String? channelLanguage,
    String? channelImage,
  }) {
    final title = _firstNonEmpty([
      _childText(element, {'title'}),
    ]);
    final enclosureUrl = _firstNonEmpty([
      _enclosureAudioUrl(element),
      _linkAudioUrl(element),
    ]);

    if (title == null || enclosureUrl == null) {
      return null;
    }

    final author = _firstNonEmpty([
      _childText(element, {'author'}),
      _childText(element, {'itunes:author'}),
      _childText(element, {'creator'}),
      _childText(element, {'dc:creator'}),
      channelAuthor,
    ]) ??
        '';

    final pubDate = _parseDate(
      _firstNonEmpty([
        _childText(element, {'pubdate'}),
        _childText(element, {'published'}),
        _childText(element, {'updated'}),
      ]),
    );

    return PodcastFeedItem(
      title: title,
      author: author,
      enclosureUrl: enclosureUrl,
      pubDate: pubDate,
      imageUrl: _firstNonEmpty([
        _attributeValue(element, 'image', 'href'),
        _attributeValue(element, 'itunes:image', 'href'),
        _childText(element, {'image'}),
        _mediaThumbnailUrl(element),
        channelImage,
      ]),
      language: _firstNonEmpty([
        _childText(element, {'language'}),
        channelLanguage,
      ]),
      category: _parseCategory(element),
      pin: _childText(element, {'pin'}),
      guid: _firstNonEmpty([
        _childText(element, {'guid'}),
        _childText(element, {'id'}),
        enclosureUrl,
        title,
      ]),
    );
  }

  String? _parseCategory(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (!_matchesLocalName(child, 'category')) {
        continue;
      }
      final text = child.innerText.trim();
      if (text.isNotEmpty) {
        return text;
      }
      final label = child.getAttribute('text')?.trim();
      if (label != null && label.isNotEmpty) {
        return label;
      }
    }
    return null;
  }

  bool _matchesLocalName(XmlElement element, String name) {
    final target = name.toLowerCase();
    final local = element.localName.toLowerCase();
    if (local == target) {
      return true;
    }
    final qualified = element.name.qualified.toLowerCase();
    return qualified == target || qualified.endsWith(':$target');
  }

  String? _childText(XmlElement parent, Set<String> names) {
    final targets = names.map((name) => name.toLowerCase()).toSet();
    for (final child in parent.children.whereType<XmlElement>()) {
      final local = child.localName.toLowerCase();
      final qualified = child.name.qualified.toLowerCase();
      final matches = targets.contains(local) ||
          targets.contains(qualified) ||
          targets.any(
            (target) =>
                target.contains(':') && qualified.endsWith(target.split(':').last),
          );
      if (!matches) {
        continue;
      }
      final text = child.innerText.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String? _attributeValue(XmlElement parent, String name, String attribute) {
    final target = name.toLowerCase();
    for (final child in parent.children.whereType<XmlElement>()) {
      final local = child.localName.toLowerCase();
      final qualified = child.name.qualified.toLowerCase();
      if (local != target &&
          qualified != target &&
          !qualified.endsWith(':$target')) {
        continue;
      }
      final value = child.getAttribute(attribute)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _enclosureAudioUrl(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (!_matchesLocalName(child, 'enclosure')) {
        continue;
      }
      final url = child.getAttribute('url')?.trim();
      if (url == null || url.isEmpty) {
        continue;
      }
      final type = child.getAttribute('type')?.toLowerCase() ?? '';
      if (type.startsWith('audio/') || _looksLikeAudioUrl(url)) {
        return url;
      }
    }
    return null;
  }

  String? _linkAudioUrl(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (!_matchesLocalName(child, 'link')) {
        continue;
      }
      final href = child.getAttribute('href')?.trim() ??
          child.innerText.trim();
      if (href.isEmpty) {
        continue;
      }
      final type = child.getAttribute('type')?.toLowerCase() ?? '';
      final rel = child.getAttribute('rel')?.toLowerCase() ?? '';
      if (type.startsWith('audio/') ||
          rel == 'enclosure' ||
          _looksLikeAudioUrl(href)) {
        return href;
      }
    }
    return null;
  }

  String? _mediaThumbnailUrl(XmlElement element) {
    for (final child in element.descendants.whereType<XmlElement>()) {
      final name = child.localName.toLowerCase();
      if (name == 'thumbnail' || name.endsWith(':thumbnail')) {
        final url = child.getAttribute('url')?.trim();
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
  }

  bool _looksLikeAudioUrl(String url) {
    final lower = url.toLowerCase();
    final path = Uri.tryParse(lower)?.path.toLowerCase() ?? lower;
    return _audioExtensions.any(path.endsWith);
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) {
      return iso;
    }
    return _parseRfc822Date(trimmed);
  }

  DateTime? _parseRfc822Date(String raw) {
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length < 4) {
      return null;
    }

    final day = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), ''));
    final month = _monthNames[parts[2].toLowerCase().substring(0, 3)];
    final year = int.tryParse(parts[3]);
    if (day == null || month == null || year == null) {
      return null;
    }

    var hour = 0;
    var minute = 0;
    var second = 0;
    if (parts.length > 4 && parts[4].contains(':')) {
      final timeParts = parts[4].split(':');
      hour = int.tryParse(timeParts.elementAtOrNull(0) ?? '') ?? 0;
      minute = int.tryParse(timeParts.elementAtOrNull(1) ?? '') ?? 0;
      second = int.tryParse(timeParts.elementAtOrNull(2) ?? '') ?? 0;
    }

    final normalizedYear = year < 100 ? 2000 + year : year;
    return DateTime.utc(normalizedYear, month, day, hour, minute, second);
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
