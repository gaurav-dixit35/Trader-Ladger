import '../domain/report_filter.dart';
import '../domain/report_repository.dart';
import '../domain/report_row.dart';
import 'report_dao.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl({required this.reportDao});

  final ReportDao reportDao;

  @override
  Future<ReportSummary> loadReport(ReportFilter filter) {
    return reportDao.loadReport(filter);
  }
}
