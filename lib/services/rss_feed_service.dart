import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/feed_sort.dart';
import '../models/sermon_feed_data.dart';
import '../models/sermon_feed_item.dart';

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

  Future<SermonFeedData> fetchFeed(String feedUrl) async {
    final trimmed = feedUrl.trim();
    if (trimmed.isEmpty) {
      return const SermonFeedData(items: []);
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

  SermonFeedData parseFeedXml(String xmlBody) {
    final document = XmlDocument.parse(xmlBody);
    final channel = _findChannel(document);
    final feedPin = channel == null ? null : _childText(channel, 'pin');
    final sortOption = FeedSortOptionLabel.fromFeedFields(
      orderBy: channel == null ? null : _childText(channel, 'order_by'),
      orderDirection:
          channel == null ? null : _childText(channel, 'order_direction'),
    );
    final items = <SermonFeedItem>[];

    for (final element in document.descendants.whereType<XmlElement>()) {
      final localName = element.localName.toLowerCase();
      if (localName != 'item' && localName != 'entry') {
        continue;
      }

      final parsed = _parseFeedElement(element);
      if (parsed != null) {
        items.add(parsed);
      }
    }

    return SermonFeedData(
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

  SermonFeedItem? _parseFeedElement(XmlElement element) {
    final sermonTitle = _firstNonEmpty([
      _childText(element, 'sermon_title'),
      _childText(element, 'title'),
    ]);
    final preachedBy = _firstNonEmpty([
      _childText(element, 'preached_by'),
      _childText(element, 'author'),
      _childText(element, 'creator'),
      _childText(element, 'itunes:author'),
    ]);
    final audioUrl = _firstNonEmpty([
      _childText(element, 'audio_url'),
      _childText(element, 'audio'),
      _enclosureAudioUrl(element),
      _linkAudioUrl(element),
    ]);

    if (sermonTitle == null || preachedBy == null || audioUrl == null) {
      return null;
    }

    final datePreached = _parseDate(_childText(element, 'date_preached'));
    final publishedDate = _parseDate(
      _firstNonEmpty([
        _childText(element, 'published_date'),
        _childText(element, 'pubDate'),
        _childText(element, 'published'),
        _childText(element, 'updated'),
      ]),
    );

    return SermonFeedItem(
      sermonTitle: sermonTitle,
      preachedBy: preachedBy,
      audioUrl: audioUrl,
      datePreached: datePreached,
      coverImage: _firstNonEmpty([
        _childText(element, 'cover_image'),
        _childText(element, 'image'),
        _attributeValue(element, 'itunes:image', 'href'),
        _mediaThumbnailUrl(element),
      ]),
      language: _childText(element, 'language'),
      category: _parseCategory(element),
      publishedDate: publishedDate,
      pin: _childText(element, 'pin'),
      id: _firstNonEmpty([
        _childText(element, 'guid'),
        _childText(element, 'id'),
        audioUrl,
        sermonTitle,
      ]),
    );
  }

  String? _parseCategory(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (child.localName.toLowerCase() == 'category') {
        final text = child.innerText.trim();
        if (text.isNotEmpty) {
          return text;
        }
        final label = child.getAttribute('text')?.trim();
        if (label != null && label.isNotEmpty) {
          return label;
        }
      }
    }
    return null;
  }

  String? _childText(XmlElement parent, String name) {
    final target = name.toLowerCase();
    for (final child in parent.children.whereType<XmlElement>()) {
      if (child.localName.toLowerCase() == target) {
        final text = child.innerText.trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return null;
  }

  String? _attributeValue(XmlElement parent, String name, String attribute) {
    final target = name.toLowerCase();
    for (final child in parent.children.whereType<XmlElement>()) {
      if (child.localName.toLowerCase() == target) {
        final value = child.getAttribute(attribute)?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  String? _enclosureAudioUrl(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (child.localName.toLowerCase() != 'enclosure') {
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
      if (child.localName.toLowerCase() != 'link') {
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
      if (name == 'thumbnail' || name == 'media:thumbnail') {
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
    return DateTime.tryParse(raw.trim());
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
