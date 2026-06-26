import 'dart:convert';

const inkPrefix = '[[INK:v1:';
const inkSuffix = ']]';

bool isInkPage(String value) =>
    value.startsWith(inkPrefix) && value.endsWith(inkSuffix);

List<List<List<double>>> decodeInkStrokes(String value) {
  if (!isInkPage(value)) return [];
  final encoded = value.substring(
    inkPrefix.length,
    value.length - inkSuffix.length,
  );
  final decoded = jsonDecode(utf8.decode(base64Decode(encoded))) as List;
  return decoded
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
