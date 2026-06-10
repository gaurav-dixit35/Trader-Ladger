import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/report_row.dart';

enum ReportExportFormat { pdf, excel }

class ReportExportService {
  const ReportExportService();

  Future<File> export({
    required ReportSummary summary,
    required ReportExportFormat format,
  }) {
    switch (format) {
      case ReportExportFormat.pdf:
        return _exportPdf(summary);
      case ReportExportFormat.excel:
        return _exportExcel(summary);
    }
  }

  Future<void> share(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> printSummary(ReportSummary summary) async {
    final file = await _exportPdf(summary);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<File> _exportPdf(ReportSummary summary) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Trader Ledger App',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Bills, Payments, Deposits, and Reports'),
          if (_singleTraderName(summary) != null)
            pw.Text('Trader: ${_singleTraderName(summary)}'),
          pw.Text('Generated: ${DateFormatter.displayDate(DateTime.now())}'),
          pw.SizedBox(height: 12),
          _pdfSummaryTable(summary),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'S.No',
              'Date',
              'Weekday',
              'Month',
              'Trader',
              'Bill',
              'Amount',
              'Cash',
              'Cheque',
              'Pending',
              'Status',
            ],
            data: [
              for (final indexed in summary.rows.indexed)
                [
                  '${indexed.$1 + 1}',
                  DateFormatter.displayDate(indexed.$2.entryDate),
                  DateFormatter.weekday(indexed.$2.entryDate),
                  DateFormatter.month(indexed.$2.entryDate),
                  indexed.$2.traderName,
                  indexed.$2.billNumber,
                  indexed.$2.billAmount.toString(),
                  indexed.$2.cashAmount.toString(),
                  indexed.$2.chequeAmount.toString(),
                  indexed.$2.pendingAmount.toString(),
                  indexed.$2.paymentStatus.name,
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final file = await _createReportFile('pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  pw.Widget _pdfSummaryTable(ReportSummary summary) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Metric', 'Value'],
      data: [
        ['Total bill', CurrencyFormatter.inr(summary.totalBillAmount)],
        ['Cash', CurrencyFormatter.inr(summary.totalCashAmount)],
        ['Cheque', CurrencyFormatter.inr(summary.totalChequeAmount)],
        ['Pending', CurrencyFormatter.inr(summary.totalPendingAmount)],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  Future<File> _exportExcel(ReportSummary summary) async {
    final excel = Excel.createExcel();
    final sheet = excel['Trader Ledger Report'];
    excel.setDefaultSheet('Trader Ledger Report');

    sheet.appendRow([TextCellValue('Trader Ledger App')]);
    sheet.appendRow([
      TextCellValue('Bills, Payments, Deposits, and Reports'),
    ]);
    sheet.appendRow([
      TextCellValue('Generated'),
      TextCellValue(DateFormatter.displayDate(DateTime.now())),
    ]);
    final traderName = _singleTraderName(summary);
    if (traderName != null) {
      sheet.appendRow([TextCellValue('Trader'), TextCellValue(traderName)]);
    }
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Total bill'),
      IntCellValue(summary.totalBillAmount),
      TextCellValue('Cash'),
      IntCellValue(summary.totalCashAmount),
      TextCellValue('Cheque'),
      IntCellValue(summary.totalChequeAmount),
      TextCellValue('Pending'),
      IntCellValue(summary.totalPendingAmount),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('S.No'),
      TextCellValue('Date'),
      TextCellValue('Weekday'),
      TextCellValue('Month'),
      TextCellValue('Trader'),
      TextCellValue('Bill Number'),
      TextCellValue('Bill Amount'),
      TextCellValue('Cash'),
      TextCellValue('Cheque'),
      TextCellValue('Cheque Number'),
      TextCellValue('Deposit Date'),
      TextCellValue('Pending'),
      TextCellValue('Status'),
      TextCellValue('Notes'),
    ]);

    for (final indexed in summary.rows.indexed) {
      final row = indexed.$2;
      sheet.appendRow([
        IntCellValue(indexed.$1 + 1),
        TextCellValue(DateFormatter.displayDate(row.entryDate)),
        TextCellValue(DateFormatter.weekday(row.entryDate)),
        TextCellValue(DateFormatter.month(row.entryDate)),
        TextCellValue(row.traderName),
        TextCellValue(row.billNumber),
        IntCellValue(row.billAmount),
        IntCellValue(row.cashAmount),
        IntCellValue(row.chequeAmount),
        TextCellValue(row.chequeNumber ?? ''),
        TextCellValue(
          row.depositDate == null
              ? ''
              : DateFormatter.displayDate(row.depositDate!),
        ),
        IntCellValue(row.pendingAmount),
        TextCellValue(row.paymentStatus.name),
        TextCellValue(row.notes ?? ''),
      ]);
    }

    final summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    summarySheet.appendRow([
      TextCellValue('Total bill'),
      IntCellValue(summary.totalBillAmount),
    ]);
    summarySheet.appendRow([
      TextCellValue('Cash'),
      IntCellValue(summary.totalCashAmount),
    ]);
    summarySheet.appendRow([
      TextCellValue('Cheque'),
      IntCellValue(summary.totalChequeAmount),
    ]);
    summarySheet.appendRow([
      TextCellValue('Pending'),
      IntCellValue(summary.totalPendingAmount),
    ]);

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Could not generate Excel report.');
    }

    final file = await _createReportFile('xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _createReportFile(String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory(p.join(directory.path, 'reports'));
    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File(
      p.join(
        reportsDirectory.path,
        'trader_ledger_report_$timestamp.$extension',
      ),
    );
  }

  String? _singleTraderName(ReportSummary summary) {
    final names = summary.rows.map((row) => row.traderName).toSet();
    if (names.length == 1) {
      return names.first;
    }

    return null;
  }
}
