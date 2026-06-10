import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../application/entry_providers.dart';
import '../widgets/entry_image_section.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryState = ref.watch(entryDetailProvider(entryId));

    return Scaffold(
      appBar: AppBar(title: const Text('Entry Details')),
      body: entryState.when(
        data: (entry) {
          if (entry == null) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Entry not found',
              message: 'This entry may have been deleted or restored later.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppLayout.spacingLg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppLayout.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill ${entry.billNumber}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppLayout.spacingSm),
                      Text(entry.traderName ?? 'Unknown trader'),
                      const SizedBox(height: AppLayout.spacingLg),
                      _AmountRow(
                        label: 'Bill amount',
                        value: CurrencyFormatter.inr(entry.billAmount),
                      ),
                      _AmountRow(
                        label: 'Cash',
                        value: CurrencyFormatter.inr(entry.cashAmount),
                      ),
                      _AmountRow(
                        label: 'Cheque',
                        value: CurrencyFormatter.inr(entry.chequeAmount),
                      ),
                      _AmountRow(
                        label: 'Pending',
                        value: CurrencyFormatter.inr(entry.pendingAmount),
                      ),
                      const Divider(),
                      _AmountRow(
                        label: 'Entry date',
                        value: DateFormatter.displayDate(entry.entryDate),
                      ),
                      if (entry.depositDate != null)
                        _AmountRow(
                          label: 'Deposit date',
                          value: DateFormatter.displayDate(entry.depositDate!),
                        ),
                      if (entry.chequeNumber?.isNotEmpty == true)
                        _AmountRow(
                          label: 'Cheque no.',
                          value: entry.chequeNumber!,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.spacingMd),
              EntryImageSection(entryId: entry.id),
            ],
          );
        },
        error: (error, stackTrace) => const AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load entry',
          message: 'Please go back and open the entry again.',
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.spacingSm),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
