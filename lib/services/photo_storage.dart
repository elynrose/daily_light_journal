import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/entry.dart';
import '../models/journal_photo.dart';

class PhotoStorage {
  PhotoStorage._();

  static final PhotoStorage instance = PhotoStorage._();

  static const _boxName = 'photos';
  static const _photosSubdir = 'journal_photos';

  static String get boxName => _boxName;

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Box<Map>? _box;
  Directory? _photosDir;

  Future<void> init({String? hivePath}) async {
    if (_box != null && _box!.isOpen && _photosDir != null) return;

    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    _box = await Hive.openBox<Map>(_boxName);
    _photosDir = await _resolvePhotosDir(hivePath);
  }

  Future<Directory> _resolvePhotosDir(String? hivePath) async {
    if (hivePath != null) {
      final dir = Directory('$hivePath/$_photosSubdir');
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_photosSubdir');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  List<JournalPhoto> getAllPhotos() {
    final box = _box;
    if (box == null) return [];

    return box.values
        .map((value) => JournalPhoto.fromMap(Map<String, dynamic>.from(value)))
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  File? getPhotoFile(JournalPhoto photo) {
    final dir = _photosDir;
    if (dir == null) return null;

    final file = File('${dir.path}/${photo.fileName}');
    return file.existsSync() ? file : null;
  }

  Future<JournalPhoto?> captureFromCamera({
    DateTime? journalDate,
    ServicePeriod? journalPeriod,
  }) {
    return _saveFromSource(
      ImageSource.camera,
      journalDate: journalDate,
      journalPeriod: journalPeriod,
    );
  }

  Future<JournalPhoto?> pickFromGallery({
    DateTime? journalDate,
    ServicePeriod? journalPeriod,
  }) {
    return _saveFromSource(
      ImageSource.gallery,
      journalDate: journalDate,
      journalPeriod: journalPeriod,
    );
  }

  Future<JournalPhoto?> _saveFromSource(
    ImageSource source, {
    DateTime? journalDate,
    ServicePeriod? journalPeriod,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (picked == null) return null;

    return saveFromFile(
      picked,
      journalDate: journalDate,
      journalPeriod: journalPeriod,
    );
  }

  Future<JournalPhoto> saveFromFile(
    XFile file, {
    DateTime? journalDate,
    ServicePeriod? journalPeriod,
    DateTime? capturedAt,
    String? id,
  }) async {
    final box = _box;
    final dir = _photosDir;
    if (box == null || dir == null) {
      throw StateError('PhotoStorage is not initialized');
    }

    final photoId = id ?? _uuid.v4();
    final extension = _extensionForPath(file.path);
    final fileName = '$photoId$extension';
    final savedFile = File('${dir.path}/$fileName');
    await File(file.path).copy(savedFile.path);

    final photo = JournalPhoto(
      id: photoId,
      fileName: fileName,
      capturedAt: capturedAt ?? DateTime.now(),
      journalDate: journalDate,
      journalPeriod: journalPeriod,
    );

    await box.put(photoId, photo.toMap());
    return photo;
  }

  Future<void> deletePhoto(String id) async {
    final box = _box;
    final dir = _photosDir;
    if (box == null || dir == null) return;

    final raw = box.get(id);
    if (raw != null) {
      final photo = JournalPhoto.fromMap(Map<String, dynamic>.from(raw));
      final file = File('${dir.path}/${photo.fileName}');
      if (file.existsSync()) {
        await file.delete();
      }
    }

    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = _box;
    final dir = _photosDir;
    if (box == null) return;

    if (dir != null && dir.existsSync()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }

    await box.clear();
  }

  Map<String, Map<String, dynamic>> exportAllRawRecords() {
    final box = _box;
    final dir = _photosDir;
    if (box == null || dir == null) return {};

    final records = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final id = key.toString();
      final metadata = Map<String, dynamic>.from(box.get(key) as Map);
      final fileName = metadata['fileName'] as String;
      final file = File('${dir.path}/$fileName');
      final payload = Map<String, dynamic>.from(metadata);
      if (file.existsSync()) {
        payload['imageBase64'] = base64Encode(file.readAsBytesSync());
      }
      records[id] = payload;
    }
    return records;
  }

  Future<void> putRawRecord(String id, Map<String, dynamic> record) async {
    final box = _box;
    final dir = _photosDir;
    if (box == null || dir == null) {
      throw StateError('PhotoStorage is not initialized');
    }

    final payload = Map<String, dynamic>.from(record);
    final imageBase64 = payload.remove('imageBase64') as String?;
    final fileName = payload['fileName'] as String;

    if (imageBase64 != null) {
      final bytes = base64Decode(imageBase64);
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
    }

    await box.put(id, payload);
  }

  String _extensionForPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') {
      return ext == '.jpeg' ? '.jpg' : ext;
    }
    return '.jpg';
  }
}
