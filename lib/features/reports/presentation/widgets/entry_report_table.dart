import 'package:flutter/material.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/report_row.dart';

enum EntryReportSort {
  latest,
  oldest,
  traderAz,
  amountLowHigh,
  amountHighLow,
  pendingHighLow,
}

class EntryReportTable extends StatefulWidget {
  const EntryReportTable({
    required this.rows,
    required this.onDeleteSelected,
    super.key,
  });

  final List<ReportRow> rows;
  final Future<void> Function(Set<String> entryIds) onDeleteSelected;

  @override
  State<EntryReportTable> createState() => _EntryReportTableState();
}

class _EntryReportTableState extends State<EntryReportTable> {
  final Set<String> _selectedIds = {};
  EntryReportSort _sort = EntryReportSort.latest;

  @override
  void didUpdateWidget(covariant EntryReportTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeIds = widget.rows.map((row) => row.entryId).toSet();
    _selectedIds.removeWhere((id) => !activeIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sortedRows();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.spacingMd),
        child: Column(
          children: [
            DropdownButtonFormField<EntryReportSort>(
              initialValue: _sort,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sort entries',
                prefixIcon: Icon(Icons.sort_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: EntryReportSort.latest,
                  child: Text('Latest to old'),
                ),
                DropdownMenuItem(
                  value: EntryReportSort.oldest,
                  child: Text('Old to latest'),
                ),
                DropdownMenuItem(
                  value: EntryReportSort.traderAz,
                  child: Text('Trader A to Z'),
                ),
                DropdownMenuItem(
                  value: EntryReportSort.amountLowHigh,
                  child: Text('Amount low to high'),
                ),
                DropdownMenuItem(
                  value: EntryReportSort.amountHighLow,
                  child: Text('Amount high to low'),
                ),
                DropdownMenuItem(
                  value: EntryReportSort.pendingHighLow,
                  child: Text('Pending high to low'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sort = value);
                }
              },
            ),
            const SizedBox(height: AppLayout.spacingMd),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () => _deleteSelected(context),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text('Delete selected (${_selectedIds.length})'),
              ),
            ),
            const SizedBox(height: AppLayout.spacingMd),
            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  dataTextStyle: Theme.of(context).textTheme.bodyLarge,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('S.No')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Weekday')),
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Trader')),
                    DataColumn(label: Text('Bill')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Cash')),
                    DataColumn(label: Text('Cheque')),
                    DataColumn(label: Text('Pending')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final indexed in rows.indexed)
                      _dataRow(indexed.$1, indexed.$2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _dataRow(int index, ReportRow row) {
    final selected = _selectedIds.contains(row.entryId);
    return DataRow(
      selected: selected,
      cells: [
        DataCell(
          Checkbox(
            value: selected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedIds.add(row.entryId);
                } else {
                  _selectedIds.remove(row.entryId);
                }
              });
            },
          ),
        ),
        DataCell(Text('${index + 1}')),
        DataCell(Text(DateFormatter.displayDate(row.entryDate))),
        DataCell(Text(DateFormatter.weekday(row.entryDate))),
        DataCell(Text(DateFormatter.month(row.entryDate))),
        DataCell(Text(row.traderName)),
        DataCell(Text(row.billNumber)),
        DataCell(Text(CurrencyFormatter.inr(row.billAmount))),
        DataCell(Text(CurrencyFormatter.inr(row.cashAmount))),
        DataCell(Text(CurrencyFormatter.inr(row.chequeAmount))),
        DataCell(Text(CurrencyFormatter.inr(row.pendingAmount))),
        DataCell(Text(row.paymentStatus.name)),
      ],
    );
  }

  List<ReportRow> _sortedRows() {
    final rows = [...widget.rows];
    switch (_sort) {
      case EntryReportSort.latest:
        rows.sort((a, b) => b.entryDate.compareTo(a.entryDate));
        break;
      case EntryReportSort.oldest:
        rows.sort((a, b) => a.entryDate.compareTo(b.entryDate));
        break;
      case EntryReportSort.traderAz:
        rows.sort((a, b) => a.traderName.compareTo(b.traderName));
        break;
      case EntryReportSort.amountLowHigh:
        rows.sort((a, b) => a.billAmount.compareTo(b.billAmount));
        break;
      case EntryReportSort.amountHighLow:
        rows.sort((a, b) => b.billAmount.compareTo(a.billAmount));
        break;
      case EntryReportSort.pendingHighLow:
        rows.sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount));
        break;
    }
    return rows;
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final selectedIds = {..._selectedIds};
    await widget.onDeleteSelected(selectedIds);
    if (!context.mounted) {
      return;
    }

    setState(_selectedIds.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedIds.length} entries moved to recycle bin'),
      ),
    );
  }
}
