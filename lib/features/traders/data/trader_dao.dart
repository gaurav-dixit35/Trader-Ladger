import 'package:sqflite/sqflite.dart';

import '../../../database/base_dao.dart';
import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../domain/trader.dart';

class TraderDao extends BaseDao {
  const TraderDao(super.localDatabase);

  Future<List<Trader>> findActive() async {
    final db = await database;
    final rows = await db.query(
      DatabaseConstants.tradersTable,
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Trader.fromMap).toList(growable: false);
  }

  Future<Trader?> findById(String id) async {
    final db = await database;
    final rows = await db.query(
      DatabaseConstants.tradersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Trader.fromMap(rows.first);
  }

  Future<List<Trader>> search(String query) async {
    final db = await database;
    final normalizedQuery = '%${query.trim()}%';
    final rows = await db.query(
      DatabaseConstants.tradersTable,
      where: '''
        is_deleted = ?
        AND (
          name LIKE ? COLLATE NOCASE
          OR mobile_number LIKE ?
        )
      ''',
      whereArgs: [0, normalizedQuery, normalizedQuery],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Trader.fromMap).toList(growable: false);
  }

  Future<void> insert(Trader trader, {Transaction? transaction}) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.insert(
      DatabaseConstants.tradersTable,
      trader.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> update(Trader trader, {Transaction? transaction}) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.update(
      DatabaseConstants.tradersTable,
      trader.toMap(),
      where: 'id = ?',
      whereArgs: [trader.id],
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
      DatabaseConstants.tradersTable,
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

  Future<void> markDeletedWithEntries(
    String id, {
    required DateTime deletedAt,
    required String syncStatus,
  }) async {
    final db = await database;
    await db.transaction((transaction) async {
      await markDeleted(
        id,
        deletedAt: deletedAt,
        syncStatus: syncStatus,
        transaction: transaction,
      );
      await transaction.update(
        DatabaseConstants.entriesTable,
        {
          'is_deleted': 1,
          'deleted_at': DatabaseValueConverters.dateTimeToMillis(deletedAt),
          'sync_status': syncStatus,
          'updated_at': DatabaseValueConverters.dateTimeToMillis(deletedAt),
        },
        where: 'trader_id = ? AND is_deleted = ?',
        whereArgs: [id, 0],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
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
      DatabaseConstants.tradersTable,
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

  Future<void> restoreWithEntries(
    String id, {
    required DateTime restoredAt,
    required String syncStatus,
    DateTime? originalDeletedAt,
  }) async {
    final db = await database;
    await db.transaction((transaction) async {
      await restore(
        id,
        restoredAt: restoredAt,
        syncStatus: syncStatus,
        transaction: transaction,
      );

      if (originalDeletedAt == null) {
        return;
      }

      await transaction.update(
        DatabaseConstants.entriesTable,
        {
          'is_deleted': 0,
          'deleted_at': null,
          'sync_status': syncStatus,
          'updated_at': DatabaseValueConverters.dateTimeToMillis(restoredAt),
        },
        where: 'trader_id = ? AND is_deleted = ? AND deleted_at = ?',
        whereArgs: [
          id,
          1,
          DatabaseValueConverters.dateTimeToMillis(originalDeletedAt),
        ],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }
}
