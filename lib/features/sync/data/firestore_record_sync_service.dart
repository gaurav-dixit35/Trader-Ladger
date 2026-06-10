import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../../../database/local_database.dart';
import '../../../database/sync_status.dart';
import '../domain/cloud_sync_result.dart';

class FirestoreRecordSyncService {
  const FirestoreRecordSyncService({
    required this.firestore,
    required this.localDatabase,
    required this.secureStorage,
    required this.userId,
  });

  static const _deviceIdKey = 'trader_ledger_sync_device_id';
  static const _batchLimit = 500;

  final FirebaseFirestore firestore;
  final LocalDatabase localDatabase;
  final FlutterSecureStorage secureStorage;
  final String? userId;

  Future<CloudSyncResult> syncNow() async {
    if (userId == null || userId!.isEmpty) {
      throw StateError('Sign in before syncing records.');
    }

    final deviceId = await _deviceId();
    final db = await localDatabase.database;

    var pushedRecords = 0;
    pushedRecords += await _pushTable(
      db: db,
      table: DatabaseConstants.tradersTable,
      deviceId: deviceId,
    );
    pushedRecords += await _pushTable(
      db: db,
      table: DatabaseConstants.entriesTable,
      deviceId: deviceId,
    );
    pushedRecords += await _pushDeletedRecords(
      db: db,
      table: DatabaseConstants.tradersTable,
      deviceId: deviceId,
    );
    pushedRecords += await _pushDeletedRecords(
      db: db,
      table: DatabaseConstants.entriesTable,
      deviceId: deviceId,
    );

    var pulledRecords = 0;
    pulledRecords += await _pullTable(
      db: db,
      table: DatabaseConstants.tradersTable,
    );
    pulledRecords += await _pullTable(
      db: db,
      table: DatabaseConstants.entriesTable,
    );

    return CloudSyncResult(
      pushedRecords: pushedRecords,
      pulledRecords: pulledRecords,
      syncedAt: DateTime.now(),
    );
  }

  Future<int> _pushTable({
    required Database db,
    required String table,
    required String deviceId,
  }) async {
    final rows = await db.query(
      table,
      where: 'sync_status != ?',
      whereArgs: [SyncStatus.synced.name],
      orderBy: 'updated_at ASC',
    );
    var pushed = 0;

    for (final row in rows) {
      final payload = Map<String, Object?>.from(row)
        ..['remote_id'] = row['id']
        ..['device_id'] = deviceId
        ..['synced_at'] = DatabaseValueConverters.dateTimeToMillis(
          DateTime.now(),
        );
      final id = payload['id']! as String;
      final updatedAt = payload['updated_at']! as int;

      await _collection(table).doc(id).set(payload, SetOptions(merge: true));

      final changedRows = await db.update(
        table,
        {
          'remote_id': id,
          'sync_status': SyncStatus.synced.name,
        },
        where: 'id = ? AND updated_at = ?',
        whereArgs: [id, updatedAt],
      );
      if (changedRows > 0) {
        pushed++;
      }
    }

    return pushed;
  }

  Future<int> _pushDeletedRecords({
    required Database db,
    required String table,
    required String deviceId,
  }) async {
    final rows = await db.query(
      DatabaseConstants.deletedRecordsTable,
      where: 'table_name = ? AND sync_status != ?',
      whereArgs: [table, SyncStatus.synced.name],
      orderBy: 'deleted_at ASC',
    );
    var pushed = 0;

    for (final row in rows) {
      final recordId = row['record_id']! as String;
      final deletedAt = row['deleted_at']! as int;
      final payload = <String, Object?>{
        'id': recordId,
        'remote_id': recordId,
        'is_deleted': 1,
        'deleted_at': deletedAt,
        'updated_at': deletedAt,
        'sync_status': SyncStatus.synced.name,
        'device_id': deviceId,
        'synced_at': DatabaseValueConverters.dateTimeToMillis(DateTime.now()),
      };

      await _collection(table).doc(recordId).set(
            payload,
            SetOptions(merge: true),
          );

      final changedRows = await db.update(
        DatabaseConstants.deletedRecordsTable,
        {'sync_status': SyncStatus.synced.name},
        where: 'id = ? AND deleted_at = ?',
        whereArgs: [row['id'], deletedAt],
      );
      if (changedRows > 0) {
        pushed++;
      }
    }

    return pushed;
  }

  Future<int> _pullTable({
    required Database db,
    required String table,
  }) async {
    final lastPulledAt = await _readIntSetting(db, _lastPullKey(table));
    Query<Map<String, dynamic>> query = _collection(table)
        .where('updated_at', isGreaterThan: lastPulledAt)
        .orderBy('updated_at')
        .limit(_batchLimit);

    DocumentSnapshot<Map<String, dynamic>>? lastDocument;
    var pulled = 0;
    var maxPulledAt = lastPulledAt;

    while (true) {
      final snapshot = await (lastDocument == null
              ? query
              : query.startAfterDocument(lastDocument))
          .get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      for (final document in snapshot.docs) {
        if (await _applyRemoteDocument(db, table, document)) {
          pulled++;
        }

        final updatedAt = document.data()['updated_at'];
        if (updatedAt is int && updatedAt > maxPulledAt) {
          maxPulledAt = updatedAt;
        }
      }

      lastDocument = snapshot.docs.last;
      if (snapshot.docs.length < _batchLimit) {
        break;
      }
    }

    if (maxPulledAt > lastPulledAt) {
      await _writeIntSetting(db, _lastPullKey(table), maxPulledAt);
    }

    return pulled;
  }

  Future<bool> _applyRemoteDocument(
    Database db,
    String table,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = Map<String, Object?>.from(document.data() ?? {})
      ..remove('device_id')
      ..remove('synced_at')
      ..['id'] = document.id
      ..['remote_id'] = document.id
      ..['sync_status'] = SyncStatus.synced.name;
    final remoteUpdatedAt = data['updated_at'];
    if (remoteUpdatedAt is! int) {
      return false;
    }

    final localRows = await db.query(
      table,
      columns: const ['id', 'updated_at', 'sync_status'],
      where: 'id = ?',
      whereArgs: [document.id],
      limit: 1,
    );

    if (localRows.isEmpty) {
      final localDeletedAt = await _localDeletedAt(db, table, document.id);
      if (localDeletedAt != null && localDeletedAt >= remoteUpdatedAt) {
        return false;
      }

      if (_isDeletePayload(data) && !_hasRequiredFields(table, data)) {
        await _writeRemoteDeleteTombstone(
          db: db,
          table: table,
          recordId: document.id,
          data: data,
          deletedAt: data['deleted_at'] as int? ?? remoteUpdatedAt,
        );
        return true;
      }

      await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    }

    final local = localRows.first;
    final localUpdatedAt = local['updated_at']! as int;
    final localSyncStatus = local['sync_status']! as String;
    final localHasNewerPendingWrite =
        localSyncStatus != SyncStatus.synced.name &&
            localUpdatedAt > remoteUpdatedAt;

    if (localHasNewerPendingWrite) {
      return false;
    }
    if (remoteUpdatedAt < localUpdatedAt &&
        localSyncStatus == SyncStatus.synced.name) {
      return false;
    }

    if (_isDeletePayload(data) && !_hasRequiredFields(table, data)) {
      await db.update(
        table,
        {
          'is_deleted': 1,
          'deleted_at': data['deleted_at'] as int? ?? remoteUpdatedAt,
          'remote_id': document.id,
          'sync_status': SyncStatus.synced.name,
          'updated_at': remoteUpdatedAt,
        },
        where: 'id = ?',
        whereArgs: [document.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    }

    await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [document.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  bool _isDeletePayload(Map<String, Object?> data) {
    return data['is_deleted'] == 1 || data['sync_status'] == 'pendingDelete';
  }

  bool _hasRequiredFields(String table, Map<String, Object?> data) {
    return switch (table) {
      DatabaseConstants.tradersTable =>
        data['name'] is String && data['created_at'] is int,
      DatabaseConstants.entriesTable =>
        data['trader_id'] is String &&
            data['entry_date'] is int &&
            data['bill_number'] is String &&
            data['created_at'] is int,
      _ => true,
    };
  }

  Future<int?> _localDeletedAt(
    Database db,
    String table,
    String recordId,
  ) async {
    final rows = await db.query(
      DatabaseConstants.deletedRecordsTable,
      columns: const ['deleted_at'],
      where: 'table_name = ? AND record_id = ?',
      whereArgs: [table, recordId],
      orderBy: 'deleted_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return rows.first['deleted_at'] as int?;
  }

  Future<void> _writeRemoteDeleteTombstone({
    required Database db,
    required String table,
    required String recordId,
    required Map<String, Object?> data,
    required int deletedAt,
  }) async {
    await db.insert(
      DatabaseConstants.deletedRecordsTable,
      {
        'id': '$table:$recordId',
        'table_name': table,
        'record_id': recordId,
        'snapshot_json': jsonEncode(data),
        'deleted_at': deletedAt,
        'restored_at': null,
        'sync_status': SyncStatus.synced.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  CollectionReference<Map<String, dynamic>> _collection(String table) {
    return firestore
        .collection('users')
        .doc(userId!)
        .collection(table);
  }

  Future<String> _deviceId() async {
    final key = '${_deviceIdKey}_${userId ?? 'signed_out'}';
    final saved = await secureStorage.read(key: key);
    if (saved != null) {
      return saved;
    }

    final deviceId = const Uuid().v4();
    await secureStorage.write(key: key, value: deviceId);
    return deviceId;
  }

  Future<int> _readIntSetting(Database db, String key) async {
    final rows = await db.query(
      DatabaseConstants.appSettingsTable,
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return 0;
    }

    return int.tryParse(rows.first['value']! as String) ?? 0;
  }

  Future<void> _writeIntSetting(Database db, String key, int value) async {
    await db.insert(
      DatabaseConstants.appSettingsTable,
      {
        'key': key,
        'value': value.toString(),
        'value_type': 'int',
        'updated_at': DatabaseValueConverters.dateTimeToMillis(DateTime.now()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _lastPullKey(String table) => 'firestore_last_pull_at_$table';
}
