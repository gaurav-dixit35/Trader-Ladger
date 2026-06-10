import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/providers/image_picker_provider.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/voice_search_bar.dart';
import '../../../traders/application/trader_providers.dart';
import '../../../traders/domain/trader.dart';
import '../../application/entry_providers.dart';
import '../../application/entry_image_providers.dart';
import '../../domain/business_entry.dart';
import '../widgets/entry_card.dart';
import '../widgets/entry_form.dart';

class EntriesScreen extends ConsumerWidget {
  const EntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesState = ref.watch(entryListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Entries'),
        actions: [
          IconButton(
            tooltip: 'New entry',
            onPressed: () => _showAddEntrySheet(context, ref),
            icon: const Icon(Icons.add_circle_outline),
          ),
          PopupMenuButton<_EntryAction>(
            tooltip: 'Entry actions',
            onSelected: (action) {
              switch (action) {
                case _EntryAction.refresh:
                  ref.read(entryListControllerProvider.notifier).load();
                case _EntryAction.deleteAll:
                  _confirmDeleteAllEntries(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _EntryAction.refresh,
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                ),
              ),
              PopupMenuItem(
                value: _EntryAction.deleteAll,
                child: ListTile(
                  leading: Icon(Icons.delete_sweep_outlined),
                  title: Text('Delete all entries'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppLayout.spacingLg),
            child: VoiceSearchBar(
              hintText: 'Search bill, trader, amount, cheque',
              onChanged: (value) {
                ref.read(entryListControllerProvider.notifier).search(value);
              },
            ),
          ),
          Expanded(
            child: entriesState.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No bill entries',
                    message:
                        'Create entries for bills, cash, cheques, and dues.',
                    action: FilledButton.icon(
                      onPressed: () => _showAddEntrySheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('New Entry'),
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.spacingLg,
                        0,
                        AppLayout.spacingLg,
                        AppLayout.spacingMd,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined),
                          const SizedBox(width: AppLayout.spacingSm),
                          Text(
                            '${entries.length} entries',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppLayout.spacingLg,
                          0,
                          AppLayout.spacingLg,
                          AppLayout.spacingLg,
                        ),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppLayout.spacingMd),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return EntryCard(
                            entry: entry,
                            onTap: () => context.push('/entries/${entry.id}'),
                            onEdit: () =>
                                _showEditEntrySheet(context, ref, entry),
                            onDelete: () => _deleteEntry(context, ref, entry),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              error: (error, stackTrace) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load entries',
                message: 'Please try refreshing the entry list.',
                action: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(entryListControllerProvider.notifier).load();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Entry'),
      ),
    );
  }

  Future<void> _showAddEntrySheet(BuildContext context, WidgetRef ref) async {
    final traders = await _loadTraders(ref);
    if (!context.mounted) {
      return;
    }
    if (traders.isEmpty) {
      _showNeedTraderMessage(context);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EntryForm(
          traders: traders,
          onPickCamera: () =>
              ref.read(imagePickerServiceProvider).captureFromCamera(),
          onPickGallery: () =>
              ref.read(imagePickerServiceProvider).pickFromGallery(),
          onSubmit: (values) async {
            final entry = await ref
                .read(entryListControllerProvider.notifier)
                .createEntry(
                  traderId: values.traderId,
                  entryDate: values.entryDate,
                  billNumber: values.billNumber,
                  billAmount: values.billAmount,
                  cashAmount: values.cashAmount,
                  chequeAmount: values.chequeAmount,
                  chequeNumber: values.chequeNumber,
                  depositDate: values.depositDate,
                  notes: values.notes,
                );
            await _attachProofImages(ref, entry.id, values.imageSourcePaths);
          },
        );
      },
    );
  }

  Future<void> _showEditEntrySheet(
    BuildContext context,
    WidgetRef ref,
    BusinessEntry entry,
  ) async {
    final traders = await _loadTraders(ref);
    if (!context.mounted) {
      return;
    }
    if (traders.isEmpty) {
      _showNeedTraderMessage(context);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EntryForm(
          traders: traders,
          initialEntry: entry,
          onPickCamera: () =>
              ref.read(imagePickerServiceProvider).captureFromCamera(),
          onPickGallery: () =>
              ref.read(imagePickerServiceProvider).pickFromGallery(),
          onSubmit: (values) async {
            final updatedEntry = entry.copyWith(
              traderId: values.traderId,
              entryDate: values.entryDate,
              billNumber: values.billNumber,
              billAmount: values.billAmount,
              cashAmount: values.cashAmount,
              chequeAmount: values.chequeAmount,
              chequeNumber: values.chequeNumber,
              clearChequeNumber:
                  values.chequeNumber == null ||
                  values.chequeNumber!.trim().isEmpty,
              depositDate: values.depositDate,
              clearDepositDate: values.depositDate == null,
              notes: values.notes,
              clearNotes: values.notes == null || values.notes!.trim().isEmpty,
            );
            await ref
                .read(entryListControllerProvider.notifier)
                .updateEntry(updatedEntry);
            await _attachProofImages(ref, entry.id, values.imageSourcePaths);
          },
        );
      },
    );
  }

  Future<List<Trader>> _loadTraders(WidgetRef ref) async {
    final tradersState = ref.read(traderListControllerProvider);
    if (tradersState.hasValue) {
      return tradersState.value ?? const [];
    }

    await ref.read(traderListControllerProvider.notifier).load();
    return ref.read(traderListControllerProvider).value ?? const [];
  }

  Future<void> _attachProofImages(
    WidgetRef ref,
    String entryId,
    List<String> imageSourcePaths,
  ) async {
    final repository = ref.read(entryImageRepositoryProvider);
    for (final sourcePath in imageSourcePaths) {
      await repository.addImage(entryId: entryId, sourcePath: sourcePath);
    }
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    BusinessEntry entry,
  ) async {
    await ref.read(entryListControllerProvider.notifier).deleteEntry(entry.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bill ${entry.billNumber} moved to recycle bin'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(entryListControllerProvider.notifier).restoreEntry(
                  entry.id,
                );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAllEntries(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_outlined),
          title: const Text('Delete all entries?'),
          content: const Text(
            'All active entries will move to the recycle bin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    final count = await ref
        .read(entryListControllerProvider.notifier)
        .deleteAllEntries();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count entries moved to recycle bin')),
    );
  }

  void _showNeedTraderMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add a trader before creating bill entries'),
      ),
    );
  }
}

enum _EntryAction {
  refresh,
  deleteAll,
}
