import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/providers/image_picker_provider.dart';
import '../../../../core/utils/phone_launcher.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../entries/application/entry_image_providers.dart';
import '../../../entries/application/entry_providers.dart';
import '../../../entries/presentation/widgets/entry_form.dart';
import '../../../reports/application/report_providers.dart';
import '../../../reports/data/report_export_service.dart';
import '../../../reports/domain/report_row.dart';
import '../../../reports/presentation/widgets/entry_report_table.dart';
import '../../application/trader_providers.dart';
import '../../domain/trader.dart';

class TraderProfileScreen extends ConsumerWidget {
  const TraderProfileScreen({required this.traderId, super.key});

  final String traderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traderState = ref.watch(traderDetailProvider(traderId));

    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle(title: 'Trader Profile')),
      body: traderState.when(
        data: (trader) {
          if (trader == null) {
            return const AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Trader not found',
              message: 'This trader may have been deleted or restored later.',
            );
          }

          final reportState = ref.watch(traderReportSummaryProvider(traderId));

          return ListView(
            padding: const EdgeInsets.all(AppLayout.spacingLg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppLayout.spacingLg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        child: Text(
                          trader.name.trim().isEmpty
                              ? '?'
                              : trader.name.trim()[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: AppLayout.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trader.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (trader.mobileNumber?.trim().isNotEmpty ==
                                true) ...[
                              const SizedBox(height: AppLayout.spacingXs),
                              Text(
                                trader.mobileNumber!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            if (trader.notes?.isNotEmpty == true) ...[
                              const SizedBox(height: AppLayout.spacingSm),
                              Text(
                                trader.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (PhoneLauncher.hasNumber(trader.mobileNumber))
                        IconButton.filledTonal(
                          tooltip: 'Call trader',
                          onPressed: () => _callTrader(context, trader),
                          icon: const Icon(Icons.call_outlined),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spacingMd),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: () => _showAddEntrySheet(context, ref, trader),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        trader.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spacingMd),
              reportState.when(
                data: (summary) {
                  if (summary.rows.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No trader entries',
                      message: 'Entries for this trader will appear here.',
                    );
                  }

                  return Column(
                    children: [
                      _TraderReportActions(summary: summary),
                      const SizedBox(height: AppLayout.spacingMd),
                      EntryReportTable(
                        rows: summary.rows,
                        onDeleteSelected: (entryIds) async {
                          await ref
                              .read(entryListControllerProvider.notifier)
                              .deleteEntries(entryIds);
                          ref.invalidate(traderReportSummaryProvider(traderId));
                        },
                      ),
                    ],
                  );
                },
                error: (error, stackTrace) => const AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load trader entries',
                  message: 'Please refresh this trader.',
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppLayout.spacingLg),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spacingMd),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.offline_pin_outlined),
                  title: const Text('Status'),
                  subtitle: Text(trader.syncLabel),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => const AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load trader',
          message: 'Please go back and open the trader again.',
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showAddEntrySheet(
    BuildContext context,
    WidgetRef ref,
    Trader trader,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EntryForm(
          traders: [trader],
          onPickCamera: () =>
              ref.read(imagePickerServiceProvider).captureFromCamera(),
          onPickGallery: () =>
              ref.read(imagePickerServiceProvider).pickFromGallery(),
          onSubmit: (values) async {
            final entry = await ref
                .read(entryListControllerProvider.notifier)
                .createEntry(
                  traderId: trader.id,
                  entryDate: values.entryDate,
                  billNumber: values.billNumber,
                  billAmount: values.billAmount,
                  cashAmount: values.cashAmount,
                  chequeAmount: values.chequeAmount,
                  chequeNumber: values.chequeNumber,
                  depositDate: values.depositDate,
                  notes: values.notes,
                );
            final imageRepository = ref.read(entryImageRepositoryProvider);
            for (final sourcePath in values.imageSourcePaths) {
              await imageRepository.addImage(
                entryId: entry.id,
                sourcePath: sourcePath,
              );
            }
            ref.invalidate(traderReportSummaryProvider(traderId));
          },
        );
      },
    );
  }

  Future<void> _callTrader(BuildContext context, Trader trader) async {
    final didOpen = await PhoneLauncher.call(trader.mobileNumber);
    if (didOpen || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open phone dialer')),
    );
  }
}

class _TraderReportActions extends ConsumerWidget {
  const _TraderReportActions({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
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
        IconButton.filledTonal(
          tooltip: 'Print trader report',
          onPressed: () => _printReport(context, ref),
          icon: const Icon(Icons.print_outlined),
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
      final file = await exportService.export(
        summary: summary,
        format: format,
      );
      await exportService.share(file);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export trader report')),
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
        const SnackBar(content: Text('Could not print trader report')),
      );
    }
  }
}
