import 'package:sqflite/sqflite.dart';

import '../../../database/base_dao.dart';
import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../domain/entry_image.dart';

class EntryImageDao extends BaseDao {
  const EntryImageDao(super.localDatabase);

  Future<List<EntryImage>> findByEntryId(String entryId) async {
    final db = await database;
    final rows = await db.query(
      DatabaseConstants.entryImagesTable,
      where: 'entry_id = ? AND is_deleted = ?',
      whereArgs: [entryId, 0],
      orderBy: 'sort_order ASC, created_at ASC',
    );

    return rows.map(EntryImage.fromMap).toList(growable: false);
  }

  Future<EntryImage?> findById(String id) async {
    final db = await database;
    final rows = await db.query(
      DatabaseConstants.entryImagesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return EntryImage.fromMap(rows.first);
  }

  Future<int> activeCount(String entryId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseConstants.entryImagesTable}
      WHERE entry_id = ? AND is_deleted = 0
      ''',
      [entryId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> nextSortOrder(String entryId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT MAX(sort_order) AS max_order
      FROM ${DatabaseConstants.entryImagesTable}
      WHERE entry_id = ?
      ''',
      [entryId],
    );

    return (Sqflite.firstIntValue(result) ?? -1) + 1;
  }

  Future<void> insert(EntryImage image, {Transaction? transaction}) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.insert(
      DatabaseConstants.entryImagesTable,
      image.toMap(),
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
      DatabaseConstants.entryImagesTable,
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

  Future<void> restore(
    String id, {
    required DateTime restoredAt,
    required String syncStatus,
    Transaction? transaction,
  }) async {
    final DatabaseExecutor executor = transaction ?? await database;
    await executor.update(
      DatabaseConstants.entryImagesTable,
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
