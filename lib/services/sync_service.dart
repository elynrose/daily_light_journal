import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app_preferences_service.dart';
import 'auth_service.dart';
import 'entry_storage.dart';
import 'song_storage.dart';

/// Offline-first cloud sync for the three user-owned data types:
/// journal entries (notes), user-added songs, and app preferences.
///
/// Firestore layout:
///   users/{uid}/entries/{entryId}
///   users/{uid}/songs/{songId}        (only user-added songs)
///   users/{uid}/meta/preferences
///
/// Conflict resolution is last-write-wins based on an `updatedAt` epoch-millis
/// field stored inside each record.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  static int nowMillis() => DateTime.now().millisecondsSinceEpoch;

  /// True once Firebase has been initialized. Guards every call so the app
  /// (and unit tests) keep working when Firebase is unavailable.
  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? get _uid => _ready ? AuthService.instance.uid : null;

  CollectionReference<Map<String, dynamic>>? _collection(String name) {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection(name);
  }

  DocumentReference<Map<String, dynamic>>? _prefsDoc() {
    final uid = _uid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('preferences');
  }

  int _updatedAt(Map<String, dynamic>? map) {
    final value = map?['updatedAt'];
    if (value is num) return value.toInt();
    return 0;
  }

  void _fireAndForget(Future<void> Function() action) {
    unawaited(() async {
      try {
        await action();
      } catch (error) {
        debugPrint('SyncService push failed: $error');
      }
    }());
  }

  // ---- Push (called after a local mutation) ----

  void pushEntry(String id, Map<String, dynamic> data) {
    final col = _collection('entries');
    if (col == null) return;
    _fireAndForget(() => col.doc(id).set(data));
  }

  void deleteEntry(String id) {
    final col = _collection('entries');
    if (col == null) return;
    _fireAndForget(() => col.doc(id).delete());
  }

  void pushSong(String id, Map<String, dynamic> data) {
    final col = _collection('songs');
    if (col == null) return;
    _fireAndForget(() => col.doc(id).set(data));
  }

  void deleteSong(String id) {
    final col = _collection('songs');
    if (col == null) return;
    _fireAndForget(() => col.doc(id).delete());
  }

  void pushPreferences(Map<String, dynamic> data) {
    final doc = _prefsDoc();
    if (doc == null) return;
    _fireAndForget(() => doc.set(data));
  }

  // ---- Pull + merge (called once after sign-in) ----

  Future<void> pullAndMerge() async {
    if (_uid == null) return;
    await Future.wait([
      _mergeEntries(),
      _mergeSongs(),
      _mergePreferences(),
    ]);
  }

  Future<void> _mergeEntries() async {
    final col = _collection('entries');
    if (col == null) return;

    final local = EntryStorage.instance.exportAllRawRecords();
    final snapshot = await col.get();
    final remote = <String, Map<String, dynamic>>{
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };

    final ids = <String>{...local.keys, ...remote.keys};
    for (final id in ids) {
      final localRecord = local[id];
      final remoteRecord = remote[id];
      final localTime = _updatedAt(localRecord);
      final remoteTime = _updatedAt(remoteRecord);

      if (localRecord != null && localTime >= remoteTime) {
        if (remoteRecord == null || remoteTime < localTime) {
          await col.doc(id).set(localRecord);
        }
      } else if (remoteRecord != null) {
        await EntryStorage.instance
            .putRawRecord(id, Map<String, dynamic>.from(remoteRecord));
      }
    }
  }

  Future<void> _mergeSongs() async {
    final col = _collection('songs');
    if (col == null) return;

    final local = SongStorage.instance.exportUserAddedRawRecords();
    final snapshot = await col.get();
    final remote = <String, Map<String, dynamic>>{
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };

    final ids = <String>{...local.keys, ...remote.keys};
    for (final id in ids) {
      final localRecord = local[id];
      final remoteRecord = remote[id];
      final localTime = _updatedAt(localRecord);
      final remoteTime = _updatedAt(remoteRecord);

      if (localRecord != null && localTime >= remoteTime) {
        if (remoteRecord == null || remoteTime < localTime) {
          await col.doc(id).set(localRecord);
        }
      } else if (remoteRecord != null) {
        final data = Map<String, dynamic>.from(remoteRecord);
        data['isUserAdded'] = true;
        await SongStorage.instance.putRawRecord(id, data);
      }
    }
  }

  Future<void> _mergePreferences() async {
    final doc = _prefsDoc();
    if (doc == null) return;

    final localMap = AppPreferencesService.instance.exportRawMap();
    final snapshot = await doc.get();
    final remoteMap = snapshot.data();

    final localTime = _updatedAt(localMap);
    final remoteTime = _updatedAt(remoteMap);

    if (remoteMap == null || localTime > remoteTime) {
      await doc.set(localMap);
    } else if (remoteTime > localTime) {
      await AppPreferencesService.instance
          .applyRemoteMap(Map<String, dynamic>.from(remoteMap));
    }
  }
}
