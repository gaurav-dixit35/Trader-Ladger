import 'package:sqflite/sqflite.dart';

import '../../../database/base_dao.dart';
import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../domain/business_entry.dart';

class EntryDao extends BaseDao {
  const EntryDao(super.localDatabase);

  Future<List<BusinessEntry>> findActive() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT e.*, t.name AS trader_name
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.is_deleted = 0
        AND t.is_deleted = 0
      ORDER BY e.entry_date DESC, e.created_at DESC
    ''');

    return rows.map(BusinessEntry.fromMap).toList(growable: false);
  }

  Future<BusinessEntry?> findById(String id) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT e.*, t.name AS trader_name
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.id = ?
        AND t.is_deleted = 0
      LIMIT 1
      ''',
      [id],
    );

    if (rows.isEmpty) {
      return null;
    }

    return BusinessEntry.fromMap(rows.first);
  }

  Future<List<BusinessEntry>> search(String query) async {
    final db = await database;
    final trimmedQuery = query.trim();
    final likeQuery = '%$trimmedQuery%';
    final amount = int.tryParse(trimmedQuery);

    final rows = await db.rawQuery(
      '''
      SELECT e.*, t.name AS trader_name
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.is_deleted = 0
        AND t.is_deleted = 0
        AND (
          e.bill_number LIKE ? COLLATE NOCASE
          OR e.cheque_number LIKE ? COLLATE NOCASE
          OR t.name LIKE ? COLLATE NOCASE
          OR e.bill_amount = ?
          OR e.cash_amount = ?
          OR e.cheque_amount = ?
          OR e.pending_amount = ?
        )
      ORDER BY e.entry_date DESC, e.created_at DESC
      ''',
      [
        likeQuery,
        likeQuery,
        likeQuery,
        amount ?? -1,
        amount ?? -1,
        amount ?? -1,
        amount ?? -1,
      ],
    );

    return rows.map(BusinessEntry.fromMap).toList(growable: false);
  }

  Future<void> insert(BusinessEntry entry, {Transaction? transaction}) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.insert(
      DatabaseConstants.entriesTable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> update(BusinessEntry entry, {Transaction? transaction}) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.update(
      DatabaseConstants.entriesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> markDeleted(
    String id, {
    required DateTime deletedAt,
    required String syncStatus,
    Transaction? transaction,
  }) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.update(
      DatabaseConstants.entriesTable,
      {
        'is_deleted': 1,
        'deleted_at': DatabaseValueConverters.dateTimeToMillis(deletedAt),
        'sync_status': syncStatus,
        'updated_at': DatabaseValueConverters.dateTimeToMillis(deletedAt),
      },
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> markAllDeleted({
    required DateTime deletedAt,
    required String syncStatus,
  }) async {
    final db = await database;
    return db.update(
      DatabaseConstants.entriesTable,
      {
        'is_deleted': 1,
        'deleted_at': DatabaseValueConverters.dateTimeToMillis(deletedAt),
        'sync_status': syncStatus,
        'updated_at': DatabaseValueConverters.dateTimeToMillis(deletedAt),
      },
      where: 'is_deleted = ?',
      whereArgs: [0],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> markManyDeleted(
    Iterable<String> ids, {
    required DateTime deletedAt,
    required String syncStatus,
  }) async {
    final idList = ids.toList(growable: false);
    if (idList.isEmpty) {
      return;
    }

    final db = await database;
    await db.transaction((transaction) async {
      for (final id in idList) {
        await markDeleted(
          id,
          deletedAt: deletedAt,
          syncStatus: syncStatus,
          transaction: transaction,
        );
      }
    });
  }

  Future<void> restore(
    String id, {
    required DateTime restoredAt,
    required String syncStatus,
    Transaction? transaction,
  }) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.update(
      DatabaseConstants.entriesTable,
      {
        'is_deleted': 0,
        'deleted_at': null,
        'sync_status': syncStatus,
        'updated_at': DatabaseValueConverters.dateTimeToMillis(restoredAt),
      },
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}
