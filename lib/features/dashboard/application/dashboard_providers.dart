import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../database/database_providers.dart';
import '../data/dashboard_dao.dart';
import '../data/dashboard_repository_impl.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return DashboardDao(localDatabase);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    dashboardDao: ref.watch(dashboardDaoProvider),
  );
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  ref.watch(dataRefreshProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.loadSummary();
});
