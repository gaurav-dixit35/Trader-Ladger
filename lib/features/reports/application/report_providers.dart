import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../database/database_providers.dart';
import '../data/report_dao.dart';
import '../data/report_export_service.dart';
import '../data/report_repository_impl.dart';
import '../domain/report_filter.dart';
import '../domain/report_repository.dart';
import '../domain/report_row.dart';

final reportDaoProvider = Provider<ReportDao>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return ReportDao(localDatabase);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(reportDao: ref.watch(reportDaoProvider));
});

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return const ReportExportService();
});

final reportFilterProvider = StateProvider<ReportFilter>((ref) {
  return const ReportFilter();
});

final reportSummaryProvider = FutureProvider<ReportSummary>((ref) {
  ref.watch(dataRefreshProvider);
  final filter = ref.watch(reportFilterProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.loadReport(filter);
});

final traderReportSummaryProvider =
    FutureProvider.family<ReportSummary, String>((ref, traderId) {
  ref.watch(dataRefreshProvider);
  final repository = ref.watch(reportRepositoryProvider);
  return repository.loadReport(ReportFilter(traderId: traderId));
});
