import 'dart:convert';

const inkPrefix = '[[INK:v1:';
const inkPrefixV2 = '[[INK:v2:';
const inkSuffix = ']]';

bool _isV1(String value) =>
    value.startsWith(inkPrefix) && value.endsWith(inkSuffix);

bool _isV2(String value) =>
    value.startsWith(inkPrefixV2) && value.endsWith(inkSuffix);

/// Whether [value] is a stored handwriting page (either legacy strokes-only
/// v1, or v2 which also carries the transcribed/typed text).
bool isInkPage(String value) => _isV1(value) || _isV2(value);

List<List<List<double>>> _decodeStrokes(dynamic decoded) {
  return (decoded as List)
      .map(
        (stroke) => (stroke as List)
            .map(
              (point) => (point as List)
                  .map((coordinate) => (coordinate as num).toDouble())
                  .toList(),
            )
            .toList(),
      )
      .toList();
}

/// Decodes just the stroke geometry from a v1 or v2 ink page.
List<List<List<double>>> decodeInkStrokes(String value) {
  if (_isV1(value)) {
    final encoded = value.substring(
      inkPrefix.length,
      value.length - inkSuffix.length,
    );
    return _decodeStrokes(jsonDecode(utf8.decode(base64Decode(encoded))));
  }
  if (_isV2(value)) {
    return decodeInkPage(value).strokes;
  }
  return [];
}

/// Encodes strokes only, using the legacy v1 format. Used by the drawing
/// surface which only knows about strokes.
String encodeInkStrokes(List<List<List<double>>> strokes) {
  final encoded = base64Encode(
    utf8.encode(jsonEncode(strokes)),
  );
  return '$inkPrefix$encoded$inkSuffix';
}

List<List<List<double>>> cloneStrokes(List<List<List<double>>> strokes) {
  return strokes
      .map(
        (stroke) => stroke
            .map((point) => List<double>.from(point))
            .toList(),
      )
      .toList();
}

/// A note page that can hold both a handwriting sketch and text, remembering
/// which one is currently shown.
class InkPageData {
  final List<List<List<double>>> strokes;
  final String text;
  final bool inkMode;

  const InkPageData({
    required this.strokes,
    required this.text,
    required this.inkMode,
  });

  bool get hasStrokes => strokes.isNotEmpty;
}

/// Decodes any page string (v2 ink, legacy v1 ink, or plain text) into its
/// sketch + text + active mode.
InkPageData decodeInkPage(String value) {
  if (_isV2(value)) {
    final encoded = value.substring(
      inkPrefixV2.length,
      value.length - inkSuffix.length,
    );
    final map =
        jsonDecode(utf8.decode(base64Decode(encoded))) as Map<String, dynamic>;
    return InkPageData(
      strokes: _decodeStrokes(map['strokes'] ?? const []),
      text: (map['text'] as String?) ?? '',
      // Anything other than an explicit 'text' mode shows the sketch.
      inkMode: (map['mode'] as String?) != 'text',
    );
  }
  if (_isV1(value)) {
    return InkPageData(
      strokes: decodeInkStrokes(value),
      text: '',
      inkMode: true,
    );
  }
  return InkPageData(strokes: const [], text: value, inkMode: false);
}

/// Encodes a page keeping both the sketch and the text. When there are no
/// strokes the page is stored as plain text so existing readers keep working.
String encodeInkPage({
  required List<List<List<double>>> strokes,
  required String text,
  required bool inkMode,
}) {
  if (strokes.isEmpty) return text;
  final payload = <String, dynamic>{
    'strokes': strokes,
    'text': text,
    'mode': inkMode ? 'ink' : 'text',
  };
  final encoded = base64Encode(utf8.encode(jsonEncode(payload)));
  return '$inkPrefixV2$encoded$inkSuffix';
}

/// Returns the readable text for a page: the text portion of a v2 page, empty
/// for a legacy strokes-only page, or the value itself for plain text.
String pageText(String value) {
  if (_isV2(value)) return decodeInkPage(value).text;
  if (_isV1(value)) return '';
  return value;
}
