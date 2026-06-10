import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../entries/application/entry_providers.dart';
import '../../application/report_providers.dart';
import '../../data/report_export_service.dart';
import '../../domain/report_filter.dart';
import '../../domain/report_row.dart';
import '../widgets/entry_report_table.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(reportSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Reports'),
        actions: [
          IconButton(
            tooltip: 'Date filter',
            onPressed: () => _pickDateRange(context, ref),
            icon: const Icon(Icons.date_range),
          ),
          PopupMenuButton<_ReportAction>(
            tooltip: 'Report options',
            onSelected: (action) {
              switch (action) {
                case _ReportAction.clearFilters:
                  ref.read(reportFilterProvider.notifier).state =
                      const ReportFilter();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ReportAction.clearFilters,
                child: ListTile(
                  leading: Icon(Icons.filter_alt_off_outlined),
                  title: Text('Clear filters'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: summaryState.when(
        data: (summary) => _ReportContent(summary: summary),
        error: (error, stackTrace) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load report',
          message: 'Please refresh reports.',
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(reportSummaryProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final currentFilter = ref.read(reportFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange:
          currentFilter.startDate == null || currentFilter.endDate == null
              ? null
              : DateTimeRange(
                  start: currentFilter.startDate!,
                  end: currentFilter.endDate!,
                ),
    );

    if (picked == null) {
      return;
    }

    ref.read(reportFilterProvider.notifier).state = currentFilter.copyWith(
      startDate: picked.start,
      endDate: picked.end,
    );
  }
}

enum _ReportAction { clearFilters }

class _ReportContent extends ConsumerWidget {
  const _ReportContent({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (summary.rows.isEmpty) {
      return AppEmptyState(
        icon: Icons.summarize_outlined,
        title: 'No report data',
        message: 'Reports will appear after bill entries are added.',
        action: OutlinedButton.icon(
          onPressed: () => ref.invalidate(reportSummaryProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppLayout.spacingLg),
      children: [
        _ReportSummaryCard(summary: summary),
        const SizedBox(height: AppLayout.spacingLg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _exportAndShare(
                      context,
                      ref,
                      ReportExportFormat.pdf,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: AppLayout.spacingMd),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportAndShare(
                      context,
                      ref,
                      ReportExportFormat.excel,
                    ),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Excel'),
                  ),
                ),
                const SizedBox(width: AppLayout.spacingMd),
                IconButton.filledTonal(
                  tooltip: 'Print',
                  onPressed: () => _printReport(context, ref),
                  icon: const Icon(Icons.print_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppLayout.spacingLg),
        EntryReportTable(
          rows: summary.rows,
          onDeleteSelected: (entryIds) async {
            await ref
                .read(entryListControllerProvider.notifier)
                .deleteEntries(entryIds);
            ref.invalidate(reportSummaryProvider);
          },
        ),
      ],
    );
  }

  Future<void> _exportAndShare(
    BuildContext context,
    WidgetRef ref,
    ReportExportFormat format,
  ) async {
    try {
      final exportService = ref.read(reportExportServiceProvider);
      final File file = await exportService.export(
        summary: summary,
        format: format,
      );
      await exportService.share(file);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export report')),
      );
    }
  }

  Future<void> _printReport(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(reportExportServiceProvider).printSummary(summary);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not print report')),
      );
    }
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _ReportMetricTile(
            icon: Icons.receipt_long_outlined,
            label: 'Total bill',
            value: CurrencyFormatter.inr(summary.totalBillAmount),
          ),
          const Divider(height: 1),
          _ReportMetricTile(
            icon: Icons.payments_outlined,
            label: 'Cash',
            value: CurrencyFormatter.inr(summary.totalCashAmount),
          ),
          const Divider(height: 1),
          _ReportMetricTile(
            icon: Icons.fact_check_outlined,
            label: 'Cheque',
            value: CurrencyFormatter.inr(summary.totalChequeAmount),
          ),
          const Divider(height: 1),
          _ReportMetricTile(
            icon: Icons.pending_actions_outlined,
            label: 'Pending',
            value: CurrencyFormatter.inr(summary.totalPendingAmount),
          ),
        ],
      ),
    );
  }
}

class _ReportMetricTile extends StatelessWidget {
  const _ReportMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
