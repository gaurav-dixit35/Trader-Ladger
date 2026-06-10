import '../../../database/base_dao.dart';
import '../../../database/database_constants.dart';
import '../../../database/database_value_converters.dart';
import '../../../models/payment_status.dart';
import '../domain/report_filter.dart';
import '../domain/report_row.dart';

class ReportDao extends BaseDao {
  const ReportDao(super.localDatabase);

  Future<ReportSummary> loadReport(ReportFilter filter) async {
    final db = await database;
    final whereParts = <String>['e.is_deleted = 0', 't.is_deleted = 0'];
    final args = <Object?>[];

    if (filter.traderId != null) {
      whereParts.add('e.trader_id = ?');
      args.add(filter.traderId);
    }
    if (filter.startDate != null) {
      whereParts.add('e.entry_date >= ?');
      args.add(DatabaseValueConverters.dateTimeToMillis(filter.startDate!));
    }
    if (filter.endDate != null) {
      final exclusiveEnd = DateTime(
        filter.endDate!.year,
        filter.endDate!.month,
        filter.endDate!.day,
      ).add(const Duration(days: 1));
      whereParts.add('e.entry_date < ?');
      args.add(DatabaseValueConverters.dateTimeToMillis(exclusiveEnd));
    }
    if (filter.pendingOnly) {
      whereParts.add('e.pending_amount > 0');
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        e.id,
        t.name AS trader_name,
        e.entry_date,
        e.bill_number,
        e.bill_amount,
        e.cash_amount,
        e.cheque_amount,
        e.cheque_number,
        e.deposit_date,
        e.pending_amount,
        e.payment_status,
        e.notes
      FROM ${DatabaseConstants.entriesTable} e
      INNER JOIN ${DatabaseConstants.tradersTable} t
        ON t.id = e.trader_id
      WHERE ${whereParts.join(' AND ')}
      ORDER BY e.entry_date DESC, t.name ASC, e.bill_number ASC
      ''',
      args,
    );

    final reportRows = rows.map((row) {
      return ReportRow(
        entryId: row['id']! as String,
        traderName: row['trader_name']! as String,
        entryDate: DatabaseValueConverters.millisToDateTime(
          row['entry_date']! as int,
        ),
        billNumber: row['bill_number']! as String,
        billAmount: _readInt(row, 'bill_amount'),
        cashAmount: _readInt(row, 'cash_amount'),
        chequeAmount: _readInt(row, 'cheque_amount'),
        chequeNumber: row['cheque_number'] as String?,
        depositDate: DatabaseValueConverters.nullableMillisToDateTime(
          row['deposit_date'] as int?,
        ),
        pendingAmount: _readInt(row, 'pending_amount'),
        paymentStatus: PaymentStatus.fromName(row['payment_status']! as String),
        notes: row['notes'] as String?,
      );
    }).toList(growable: false);

    return ReportSummary(
      rows: reportRows,
      totalBillAmount: _sum(reportRows, (row) => row.billAmount),
      totalCashAmount: _sum(reportRows, (row) => row.cashAmount),
      totalChequeAmount: _sum(reportRows, (row) => row.chequeAmount),
      totalPendingAmount: _sum(reportRows, (row) => row.pendingAmount),
    );
  }

  int _sum(List<ReportRow> rows, int Function(ReportRow row) selector) {
    return rows.fold<int>(0, (total, row) => total + selector(row));
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
