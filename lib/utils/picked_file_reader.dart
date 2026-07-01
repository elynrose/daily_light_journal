import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<String?> readPickedFileText(
  FilePickerResult? result, {
  Encoding encoding = utf8,
}) async {
  final file = result?.files.single;
  if (file == null) return null;

  final bytes = file.bytes;
  if (bytes != null) {
    return encoding.decode(bytes);
  }

  final path = file.path;
  if (path == null) return null;
  return File(path).readAsString(encoding: encoding);
}
