import 'dart:convert';

import 'entry_storage.dart';
import 'photo_storage.dart';
import 'song_storage.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const _version = '1';
  static const _header = 'church_journal_backup_version,record_type,record_id,payload';

  Future<String> exportToCsv() async {
    final lines = <String>[_header];

    for (final entry in EntryStorage.instance.exportAllRawRecords().entries) {
      lines.add(_csvRow('entry', entry.key, jsonEncode(entry.value)));
    }

    for (final song in SongStorage.instance.exportAllRawRecords().entries) {
      lines.add(_csvRow('song', song.key, jsonEncode(song.value)));
    }

    for (final photo in PhotoStorage.instance.exportAllRawRecords().entries) {
      lines.add(_csvRow('photo', photo.key, jsonEncode(photo.value)));
    }

    return lines.join('\n');
  }

  Future<BackupImportResult> importFromCsv(String csv, {bool replace = true}) async {
    final lines = const LineSplitter().convert(csv.trim());
    if (lines.isEmpty) {
      throw const FormatException('Backup file is empty');
    }

    final header = lines.first.trim();
    if (!header.startsWith('church_journal_backup_version')) {
      throw const FormatException('Unrecognized backup file format');
    }

    final entryRecords = <String, Map<String, dynamic>>{};
    final songRecords = <String, Map<String, dynamic>>{};
    final photoRecords = <String, Map<String, dynamic>>{};

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final row = _parseCsvRow(line);
      if (row.length < 4) continue;

      final recordType = row[1];
      final recordId = row[2];
      final payload = jsonDecode(row[3]) as Map<String, dynamic>;

      if (recordType == 'entry') {
        entryRecords[recordId] = payload;
      } else if (recordType == 'song') {
        songRecords[recordId] = payload;
      } else if (recordType == 'photo') {
        photoRecords[recordId] = payload;
      }
    }

    if (replace) {
      await EntryStorage.instance.clearAll();
      await SongStorage.instance.clearAll();
      await PhotoStorage.instance.clearAll();
    }

    for (final entry in entryRecords.entries) {
      await EntryStorage.instance.putRawRecord(entry.key, entry.value);
    }
    for (final song in songRecords.entries) {
      await SongStorage.instance.putRawRecord(song.key, song.value);
    }
    for (final photo in photoRecords.entries) {
      await PhotoStorage.instance.putRawRecord(photo.key, photo.value);
    }

    return BackupImportResult(
      entriesImported: entryRecords.length,
      songsImported: songRecords.length,
      photosImported: photoRecords.length,
    );
  }

  String _csvRow(String recordType, String recordId, String payload) {
    return [
      _version,
      _escape(recordType),
      _escape(recordId),
      _escape(payload),
    ].join(',');
  }

  String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  List<String> _parseCsvRow(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }

    result.add(buffer.toString());
    return result;
  }
}

class BackupImportResult {
  final int entriesImported;
  final int songsImported;
  final int photosImported;

  const BackupImportResult({
    required this.entriesImported,
    required this.songsImported,
    this.photosImported = 0,
  });
}
