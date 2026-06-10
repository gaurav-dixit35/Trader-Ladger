class DatabaseConstants {
  const DatabaseConstants._();

  static const fileName = 'trader_ledger_local.db';
  static const version = 1;

  static const tradersTable = 'traders';
  static const entriesTable = 'entries';
  static const entryImagesTable = 'entry_images';
  static const deletedRecordsTable = 'deleted_records';
  static const syncQueueTable = 'sync_queue';
  static const appSettingsTable = 'app_settings';

  static const coreTables = [
    appSettingsTable,
    tradersTable,
    entriesTable,
    entryImagesTable,
    deletedRecordsTable,
    syncQueueTable,
  ];
}
