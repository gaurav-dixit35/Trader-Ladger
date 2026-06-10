import '../../../models/payment_status.dart';

class ReportRow {
  const ReportRow({
    required this.entryId,
    required this.traderName,
    required this.entryDate,
    required this.billNumber,
    required this.billAmount,
    required this.cashAmount,
    required this.chequeAmount,
    required this.pendingAmount,
    required this.paymentStatus,
    this.chequeNumber,
    this.depositDate,
    this.notes,
  });

  final String entryId;
  final String traderName;
  final DateTime entryDate;
  final String billNumber;
  final int billAmount;
  final int cashAmount;
  final int chequeAmount;
  final int pendingAmount;
  final PaymentStatus paymentStatus;
  final String? chequeNumber;
  final DateTime? depositDate;
  final String? notes;
}

class ReportSummary {
  const ReportSummary({
    required this.rows,
    required this.totalBillAmount,
    required this.totalCashAmount,
    required this.totalChequeAmount,
    required this.totalPendingAmount,
  });

  final List<ReportRow> rows;
  final int totalBillAmount;
  final int totalCashAmount;
  final int totalChequeAmount;
  final int totalPendingAmount;
}
