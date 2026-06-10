import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/utils/phone_launcher.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/voice_search_bar.dart';
import '../../application/trader_providers.dart';
import '../../domain/trader.dart';
import '../widgets/trader_card.dart';
import '../widgets/trader_form.dart';

class TradersScreen extends ConsumerWidget {
  const TradersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradersState = ref.watch(traderListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Traders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(traderListControllerProvider.notifier).load();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppLayout.spacingLg),
            child: VoiceSearchBar(
              hintText: 'Search traders',
              onChanged: (value) {
                ref.read(traderListControllerProvider.notifier).search(value);
              },
            ),
          ),
          Expanded(
            child: tradersState.when(
              data: (traders) {
                if (traders.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No traders yet',
                    message:
                        'Add traders to manage bills, collections, and dues.',
                    action: FilledButton.icon(
                      onPressed: () => _showAddTraderSheet(context, ref),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Trader'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.spacingLg,
                    0,
                    AppLayout.spacingLg,
                    AppLayout.spacingLg,
                  ),
                  itemCount: traders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppLayout.spacingMd),
                  itemBuilder: (context, index) {
                    final trader = traders[index];
                    return TraderCard(
                      trader: trader,
                      onTap: () => context.push('/traders/${trader.id}'),
                      onCall: () => _callTrader(context, trader),
                      onEdit: () => _showEditTraderSheet(context, ref, trader),
                      onDelete: () => _deleteTrader(context, ref, trader),
                    );
                  },
                );
              },
              error: (error, stackTrace) => AppEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load traders',
                message: 'Please try refreshing the trader list.',
                action: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(traderListControllerProvider.notifier).load();
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
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add trader',
        onPressed: () => _showAddTraderSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTraderSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return TraderForm(
          onSubmit: ({
            required String name,
            String? mobileNumber,
            String? notes,
          }) {
            return ref
                .read(traderListControllerProvider.notifier)
                .createTrader(
                  name: name,
                  mobileNumber: mobileNumber,
                  notes: notes,
                );
          },
        );
      },
    );
  }

  void _showEditTraderSheet(
    BuildContext context,
    WidgetRef ref,
    Trader trader,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return TraderForm(
          initialTrader: trader,
          onSubmit: ({
            required String name,
            String? mobileNumber,
            String? notes,
          }) {
            final normalizedMobile = mobileNumber?.trim();
            final normalizedNotes = notes?.trim();
            final updatedTrader = trader.copyWith(
              name: name.trim(),
              mobileNumber: normalizedMobile,
              clearMobileNumber:
                  normalizedMobile == null || normalizedMobile.isEmpty,
              notes: normalizedNotes,
              clearNotes: normalizedNotes == null || normalizedNotes.isEmpty,
            );
            return ref
                .read(traderListControllerProvider.notifier)
                .updateTrader(updatedTrader);
          },
        );
      },
    );
  }

  Future<void> _deleteTrader(
    BuildContext context,
    WidgetRef ref,
    Trader trader,
  ) async {
    await ref.read(traderListControllerProvider.notifier).deleteTrader(
          trader.id,
        );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${trader.name} moved to recycle bin'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(traderListControllerProvider.notifier).restoreTrader(
                  trader.id,
                );
          },
        ),
      ),
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
