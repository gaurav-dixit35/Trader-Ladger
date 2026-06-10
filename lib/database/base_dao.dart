import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

abstract class BaseDao {
  const BaseDao(this.localDatabase);

  final LocalDatabase localDatabase;

  Future<Database> get database => localDatabase.database;

  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) {
    return localDatabase.transaction(action);
  }
}
