import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';
import 'database_migrations.dart';

class LocalDatabase {
  LocalDatabase({required this.userId});

  final String userId;

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final existingOpen = _openingDatabase;
    if (existingOpen != null) {
      return existingOpen;
    }

    final opening = _open();
    _openingDatabase = opening;

    try {
      final opened = await opening;
      _database = opened;
      return opened;
    } finally {
      _openingDatabase = null;
    }
  }

  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> close() async {
    final opening = _openingDatabase;
    if (opening != null) {
      await opening;
    }

    final existing = _database;
    if (existing == null) {
      return;
    }

    await existing.close();
    _database = null;
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final databasePath = p.join(
      databasesPath,
      _databaseFileName,
    );

    return openDatabase(
      databasePath,
      version: DatabaseConstants.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await DatabaseMigrations.createV1(db);
      },
      onUpgrade: DatabaseMigrations.upgrade,
    );
  }

  String get _databaseFileName {
    final safeUserId = userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${p.basenameWithoutExtension(DatabaseConstants.fileName)}_'
        '$safeUserId${p.extension(DatabaseConstants.fileName)}';
  }
}
