import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_dao.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({required this.dashboardDao});

  final DashboardDao dashboardDao;

  @override
  Future<DashboardSummary> loadSummary() {
    return dashboardDao.loadSummary();
  }
}
