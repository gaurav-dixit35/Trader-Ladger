import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class DatabaseMigrations {
  const DatabaseMigrations._();

  static Future<void> createV1(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.appSettingsTable} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        value_type TEXT NOT NULL DEFAULT 'string',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tradersTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mobile_number TEXT,
        notes TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        remote_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        CHECK (is_deleted IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.entriesTable} (
        id TEXT PRIMARY KEY,
        trader_id TEXT NOT NULL,
        entry_date INTEGER NOT NULL,
        bill_number TEXT NOT NULL,
        bill_amount INTEGER NOT NULL DEFAULT 0,
        cash_amount INTEGER NOT NULL DEFAULT 0,
        cheque_amount INTEGER NOT NULL DEFAULT 0,
        cheque_number TEXT,
        deposit_date INTEGER,
        pending_amount INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        remote_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (trader_id)
          REFERENCES ${DatabaseConstants.tradersTable} (id)
          ON DELETE RESTRICT,
        CHECK (bill_amount >= 0),
        CHECK (cash_amount >= 0),
        CHECK (cheque_amount >= 0),
        CHECK (pending_amount >= 0),
        CHECK (is_deleted IN (0, 1)),
        CHECK (payment_status IN ('paid', 'pending', 'partial'))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.entryImagesTable} (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        remote_path TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        remote_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (entry_id)
          REFERENCES ${DatabaseConstants.entriesTable} (id)
          ON DELETE CASCADE,
        CHECK (is_deleted IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.deletedRecordsTable} (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        snapshot_json TEXT NOT NULL,
        deleted_at INTEGER NOT NULL,
        restored_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate'
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.syncQueueTable} (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_retry_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        CHECK (operation IN ('create', 'update', 'delete', 'restore'))
      )
    ''');

    await _createIndexes(db);
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < newVersion) {
      throw UnsupportedError(
        'Missing migration from database v$oldVersion to v$newVersion.',
      );
    }
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX idx_traders_name '
      'ON ${DatabaseConstants.tradersTable} (name)',
    );
    await db.execute(
      'CREATE INDEX idx_traders_mobile '
      'ON ${DatabaseConstants.tradersTable} (mobile_number)',
    );
    await db.execute(
      'CREATE INDEX idx_entries_trader '
      'ON ${DatabaseConstants.entriesTable} (trader_id)',
    );
    await db.execute(
      'CREATE INDEX idx_entries_date '
      'ON ${DatabaseConstants.entriesTable} (entry_date)',
    );
    await db.execute(
      'CREATE INDEX idx_entries_bill_number '
      'ON ${DatabaseConstants.entriesTable} (bill_number)',
    );
    await db.execute(
      'CREATE INDEX idx_entries_cheque_number '
      'ON ${DatabaseConstants.entriesTable} (cheque_number)',
    );
    await db.execute(
      'CREATE INDEX idx_entries_payment_status '
      'ON ${DatabaseConstants.entriesTable} (payment_status)',
    );
    await db.execute(
      'CREATE INDEX idx_entry_images_entry '
      'ON ${DatabaseConstants.entryImagesTable} (entry_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_retry '
      'ON ${DatabaseConstants.syncQueueTable} (next_retry_at)',
    );
  }
}
