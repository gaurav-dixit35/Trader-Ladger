import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../features/auth/application/auth_providers.dart';
import 'database_health_check.dart';
import 'local_database.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  final localDatabase = LocalDatabase(userId: user?.id ?? 'signed_out');
  ref.onDispose(() {
    unawaited(localDatabase.close());
  });
  return localDatabase;
});

final databaseProvider = FutureProvider<Database>((ref) async {
  final localDatabase = ref.watch(localDatabaseProvider);
  return localDatabase.database;
});

final databaseHealthCheckProvider = Provider<DatabaseHealthCheck>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return DatabaseHealthCheck(localDatabase);
});

final databaseHealthStatusProvider =
    FutureProvider<DatabaseHealthStatus>((ref) async {
  final healthCheck = ref.watch(databaseHealthCheckProvider);
  return healthCheck.verify();
});
