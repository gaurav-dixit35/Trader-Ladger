import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../../database/base_dao.dart';
import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../../../database/sync_status.dart';
import '../domain/recycle_bin_item.dart';

class RecycleBinDao extends BaseDao {
  const RecycleBinDao(super.localDatabase);

  Future<List<RecycleBinItem>> findDeletedItems() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        id,
        'trader' AS type,
        name AS title,
        COALESCE(mobile_number, 'Trader account') AS subtitle,
        deleted_at
      FROM ${DatabaseConstants.tradersTable}
      WHERE is_deleted = 1 AND deleted_at IS NOT NULL
      UNION ALL
      SELECT
        e.id,
        'entry' AS type,
        'Bill ' || e.bill_number AS title,
        COALESCE(t.name, 'Bill entry') AS subtitle,
        e.deleted_at
      FROM ${DatabaseConstants.entriesTable} e
      LEFT JOIN ${DatabaseConstants.tradersTable} t ON t.id = e.trader_id
      WHERE e.is_deleted = 1 AND e.deleted_at IS NOT NULL
      ORDER BY deleted_at DESC
    ''');

    return rows.map(_mapRow).toList(growable: false);
  }

  Future<void> restoreItem(RecycleBinItem item) async {
    final now = DateTime.now();
    final db = await database;
    await db.transaction((transaction) async {
      switch (item.type) {
        case RecycleBinItemType.trader:
          await _restoreTraderWithEntries(
            transaction: transaction,
            traderId: item.id,
            deletedAt: item.deletedAt,
            restoredAt: now,
          );
        case RecycleBinItemType.entry:
          await _restoreEntryWithTrader(
            transaction: transaction,
            entryId: item.id,
            restoredAt: now,
          );
      }
    });
  }

  Future<void> restoreAll() async {
    final db = await database;
    await db.transaction((transaction) async {
      final now = DateTime.now();
      await _restoreRows(
        transaction: transaction,
        table: DatabaseConstants.tradersTable,
        restoredAt: now,
      );
      await _restoreRows(
        transaction: transaction,
        table: DatabaseConstants.entriesTable,
        restoredAt: now,
      );
    });
  }

  Future<void> permanentlyDeleteItem(RecycleBinItem item) async {
    final db = await database;
    await db.transaction((transaction) async {
      switch (item.type) {
        case RecycleBinItemType.trader:
          await _permanentlyDeleteTrader(transaction, item.id);
        case RecycleBinItemType.entry:
          await _permanentlyDeleteEntry(transaction, item.id);
      }
    });
  }

  Future<void> emptyRecycleBin() async {
    final db = await database;
    await db.transaction((transaction) async {
      final deletedEntries = await transaction.query(
        DatabaseConstants.entriesTable,
        columns: const ['id'],
        where: 'is_deleted = ?',
        whereArgs: [1],
      );
      for (final entry in deletedEntries) {
        await _permanentlyDeleteEntry(transaction, entry['id']! as String);
      }

      final deletedTraders = await transaction.query(
        DatabaseConstants.tradersTable,
        columns: const ['id'],
        where: 'is_deleted = ?',
        whereArgs: [1],
      );
      for (final trader in deletedTraders) {
        await _permanentlyDeleteTrader(transaction, trader['id']! as String);
      }
    });
  }

  Future<void> _restoreRowInTransaction({
    required Transaction transaction,
    required String table,
    required String id,
    required DateTime restoredAt,
  }) async {
    await transaction.update(
      table,
      _restoreValues(restoredAt),
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> _restoreTraderWithEntries({
    required Transaction transaction,
    required String traderId,
    required DateTime deletedAt,
    required DateTime restoredAt,
  }) async {
    await _restoreRowInTransaction(
      transaction: transaction,
      table: DatabaseConstants.tradersTable,
      id: traderId,
      restoredAt: restoredAt,
    );

    await transaction.update(
      DatabaseConstants.entriesTable,
      _restoreValues(restoredAt),
      where: 'trader_id = ? AND is_deleted = ? AND deleted_at = ?',
      whereArgs: [
        traderId,
        1,
        DatabaseValueConverters.dateTimeToMillis(deletedAt),
      ],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> _restoreEntryWithTrader({
    required Transaction transaction,
    required String entryId,
    required DateTime restoredAt,
  }) async {
    final entryRows = await transaction.query(
      DatabaseConstants.entriesTable,
      columns: const ['trader_id'],
      where: 'id = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    if (entryRows.isEmpty) {
      return;
    }

    final traderId = entryRows.first['trader_id']! as String;
    final traderRows = await transaction.query(
      DatabaseConstants.tradersTable,
      columns: const ['is_deleted'],
      where: 'id = ?',
      whereArgs: [traderId],
      limit: 1,
    );
    final isTraderDeleted =
        traderRows.isNotEmpty && traderRows.first['is_deleted'] == 1;
    if (isTraderDeleted) {
      await _restoreRowInTransaction(
        transaction: transaction,
        table: DatabaseConstants.tradersTable,
        id: traderId,
        restoredAt: restoredAt,
      );
    }

    await _restoreRowInTransaction(
      transaction: transaction,
      table: DatabaseConstants.entriesTable,
      id: entryId,
      restoredAt: restoredAt,
    );
  }

  Future<void> _restoreRows({
    required Transaction transaction,
    required String table,
    required DateTime restoredAt,
  }) async {
    await transaction.update(
      table,
      _restoreValues(restoredAt),
      where: 'is_deleted = ?',
      whereArgs: [1],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Map<String, Object?> _restoreValues(DateTime restoredAt) {
    return {
      'is_deleted': 0,
      'deleted_at': null,
      'sync_status': SyncStatus.pendingUpdate.name,
      'updated_at': DatabaseValueConverters.dateTimeToMillis(restoredAt),
    };
  }

  RecycleBinItem _mapRow(Map<String, Object?> row) {
    final typeName = row['type']! as String;
    final deletedAt = row['deleted_at']! as int;

    return RecycleBinItem(
      id: row['id']! as String,
      type: typeName == 'trader'
          ? RecycleBinItemType.trader
          : RecycleBinItemType.entry,
      title: row['title']! as String,
      subtitle: row['subtitle']! as String,
      deletedAt: DatabaseValueConverters.millisToDateTime(deletedAt),
    );
  }

  Future<void> _permanentlyDeleteTrader(
    Transaction transaction,
    String traderId,
  ) async {
    final relatedEntries = await transaction.query(
      DatabaseConstants.entriesTable,
      where: 'trader_id = ?',
      whereArgs: [traderId],
    );

    for (final entry in relatedEntries) {
      await _writeDeleteTombstone(
        transaction: transaction,
        table: DatabaseConstants.entriesTable,
        row: entry,
      );
      await _deleteEntryImages(transaction, entry['id']! as String);
    }

    await transaction.delete(
      DatabaseConstants.entriesTable,
      where: 'trader_id = ?',
      whereArgs: [traderId],
    );

    final traderRows = await transaction.query(
      DatabaseConstants.tradersTable,
      where: 'id = ?',
      whereArgs: [traderId],
      limit: 1,
    );
    if (traderRows.isNotEmpty) {
      await _writeDeleteTombstone(
        transaction: transaction,
        table: DatabaseConstants.tradersTable,
        row: traderRows.first,
      );
    }

    await transaction.delete(
      DatabaseConstants.tradersTable,
      where: 'id = ?',
      whereArgs: [traderId],
    );
  }

  Future<void> _permanentlyDeleteEntry(
    Transaction transaction,
    String entryId,
  ) async {
    final entryRows = await transaction.query(
      DatabaseConstants.entriesTable,
      where: 'id = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    if (entryRows.isNotEmpty) {
      await _writeDeleteTombstone(
        transaction: transaction,
        table: DatabaseConstants.entriesTable,
        row: entryRows.first,
      );
    }

    await _deleteEntryImages(transaction, entryId);
    await transaction.delete(
      DatabaseConstants.entriesTable,
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> _deleteEntryImages(
    Transaction transaction,
    String entryId,
  ) async {
    final images = await transaction.query(
      DatabaseConstants.entryImagesTable,
      columns: const ['local_path'],
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );

    for (final image in images) {
      final localPath = image['local_path'] as String?;
      if (localPath == null || localPath.isEmpty) {
        continue;
      }

      final file = File(localPath);
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // Keep permanent delete working even if an image file is already moved.
      }
    }

    await transaction.delete(
      DatabaseConstants.entryImagesTable,
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> _writeDeleteTombstone({
    required Transaction transaction,
    required String table,
    required Map<String, Object?> row,
  }) async {
    final recordId = row['id']! as String;
    final deletedAt = DatabaseValueConverters.dateTimeToMillis(DateTime.now());

    await transaction.insert(
      DatabaseConstants.deletedRecordsTable,
      {
        'id': '$table:$recordId',
        'table_name': table,
        'record_id': recordId,
        'snapshot_json': jsonEncode(row),
        'deleted_at': deletedAt,
        'restored_at': null,
        'sync_status': SyncStatus.pendingDelete.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
