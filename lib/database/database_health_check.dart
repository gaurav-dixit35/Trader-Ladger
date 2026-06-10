import 'database_constants.dart';
import 'local_database.dart';

class DatabaseHealthCheck {
  const DatabaseHealthCheck(this.localDatabase);

  final LocalDatabase localDatabase;

  Future<DatabaseHealthStatus> verify() async {
    final db = await localDatabase.database;
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final availableTables = rows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();

    final missingTables = DatabaseConstants.coreTables
        .where((table) => !availableTables.contains(table))
        .toList(growable: false);

    return DatabaseHealthStatus(
      isReady: missingTables.isEmpty,
      availableTables: availableTables,
      missingTables: missingTables,
    );
  }
}

class DatabaseHealthStatus {
  const DatabaseHealthStatus({
    required this.isReady,
    required this.availableTables,
    required this.missingTables,
  });

  final bool isReady;
  final Set<String> availableTables;
  final List<String> missingTables;
}
