import 'report_filter.dart';
import 'report_row.dart';

abstract class ReportRepository {
  Future<ReportSummary> loadReport(ReportFilter filter);
}
