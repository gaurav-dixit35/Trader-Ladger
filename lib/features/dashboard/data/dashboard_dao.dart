import '../../../database/base_dao.dart';
import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../domain/dashboard_summary.dart';

class DashboardDao extends BaseDao {
  const DashboardDao(super.localDatabase);

  Future<DashboardSummary> loadSummary() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final nextWeekEnd = todayStart.add(const Duration(days: 7));

    final overallRows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(bill_amount), 0) AS total_bill_amount,
        COALESCE(SUM(cash_amount), 0) AS total_cash_amount,
        COALESCE(SUM(cheque_amount), 0) AS total_cheque_amount,
        COALESCE(SUM(pending_amount), 0) AS pending_amount
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.is_deleted = 0
        AND t.is_deleted = 0
    ''');
    final overall = overallRows.first;

    final todayCollection = await _collectionBetween(todayStart, tomorrowStart);
    final weeklyCollection = await _collectionBetween(weekStart, tomorrowStart);
    final monthlyCollection = await _collectionBetween(monthStart, tomorrowStart);
    final upcomingDeposits = await _upcomingDeposits(todayStart, nextWeekEnd);
    final traderTotals = await _traderTotals();

    return DashboardSummary(
      totalBillAmount: _readInt(overall, 'total_bill_amount'),
      totalCashAmount: _readInt(overall, 'total_cash_amount'),
      totalChequeAmount: _readInt(overall, 'total_cheque_amount'),
      pendingAmount: _readInt(overall, 'pending_amount'),
      todayCollection: todayCollection,
      weeklyCollection: weeklyCollection,
      monthlyCollection: monthlyCollection,
      upcomingDepositAmount: upcomingDeposits.amount,
      upcomingDepositCount: upcomingDeposits.count,
      traderTotals: traderTotals,
    );
  }

  Future<int> _collectionBetween(DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(cash_amount + cheque_amount), 0) AS collection
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.is_deleted = 0
        AND t.is_deleted = 0
        AND e.entry_date >= ?
        AND e.entry_date < ?
      ''',
      [
        DatabaseValueConverters.dateTimeToMillis(start),
        DatabaseValueConverters.dateTimeToMillis(end),
      ],
    );

    return _readInt(rows.first, 'collection');
  }

  Future<_UpcomingDepositSummary> _upcomingDeposits(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS deposit_count,
        COALESCE(SUM(cheque_amount), 0) AS deposit_amount
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE e.is_deleted = 0
        AND t.is_deleted = 0
        AND e.cheque_amount > 0
        AND e.deposit_date IS NOT NULL
        AND e.deposit_date >= ?
        AND e.deposit_date < ?
      ''',
      [
        DatabaseValueConverters.dateTimeToMillis(start),
        DatabaseValueConverters.dateTimeToMillis(end),
      ],
    );

    final row = rows.first;
    return _UpcomingDepositSummary(
      count: _readInt(row, 'deposit_count'),
      amount: _readInt(row, 'deposit_amount'),
    );
  }

  Future<List<TraderDashboardTotal>> _traderTotals() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        t.id AS trader_id,
        t.name AS trader_name,
        COALESCE(SUM(e.bill_amount), 0) AS total_bill_amount,
        COALESCE(SUM(e.pending_amount), 0) AS pending_amount
      FROM ${DatabaseConstants.tradersTable} t
      LEFT JOIN ${DatabaseConstants.entriesTable} e
        ON e.trader_id = t.id AND e.is_deleted = 0
      WHERE t.is_deleted = 0
      GROUP BY t.id, t.name
      ORDER BY pending_amount DESC, total_bill_amount DESC, t.name ASC
      LIMIT 5
    ''');

    return rows.map((row) {
      return TraderDashboardTotal(
        traderId: row['trader_id']! as String,
        traderName: row['trader_name']! as String,
        totalBillAmount: _readInt(row, 'total_bill_amount'),
        pendingAmount: _readInt(row, 'pending_amount'),
      );
    }).toList(growable: false);
  }

  int _readInt(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}

class _UpcomingDepositSummary {
  const _UpcomingDepositSummary({
    required this.count,
    required this.amount,
  });

  final int count;
  final int amount;
}
