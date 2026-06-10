import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_layout.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../application/recycle_bin_providers.dart';
import '../../domain/recycle_bin_item.dart';

class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recycleBinState = ref.watch(recycleBinControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Recycle Bin'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(recycleBinControllerProvider.notifier).load();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Restore all',
            onPressed: recycleBinState.maybeWhen(
              data: (items) => items.isEmpty
                  ? null
                  : () => _restoreAll(context, ref),
              orElse: () => null,
            ),
            icon: const Icon(Icons.restore),
          ),
          IconButton(
            tooltip: 'Empty recycle bin',
            onPressed: recycleBinState.maybeWhen(
              data: (items) => items.isEmpty
                  ? null
                  : () => _emptyRecycleBin(context, ref),
              orElse: () => null,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
          ),
        ],
      ),
      body: recycleBinState.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.delete_outline,
              title: 'Recycle bin is empty',
              message: 'Deleted traders and entries will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppLayout.spacingLg),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppLayout.spacingMd),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: Icon(_iconFor(item.type)),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.subtitle}\nDeleted ${DateFormatter.displayDate(item.deletedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Restore',
                          onPressed: () => _restoreItem(context, ref, item),
                          icon: const Icon(Icons.restore_from_trash_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete permanently',
                          onPressed: () =>
                              _permanentlyDeleteItem(context, ref, item),
                          icon: const Icon(Icons.delete_forever_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        error: (error, stackTrace) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load recycle bin',
          message: 'Please try refreshing.',
          action: OutlinedButton.icon(
            onPressed: () {
              ref.read(recycleBinControllerProvider.notifier).load();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  IconData _iconFor(RecycleBinItemType type) {
    return switch (type) {
      RecycleBinItemType.trader => Icons.groups_outlined,
      RecycleBinItemType.entry => Icons.receipt_long_outlined,
    };
  }

  Future<void> _restoreItem(
    BuildContext context,
    WidgetRef ref,
    RecycleBinItem item,
  ) async {
    await ref.read(recycleBinControllerProvider.notifier).restoreItem(item);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} restored')),
    );
  }

  Future<void> _restoreAll(BuildContext context, WidgetRef ref) async {
    await ref.read(recycleBinControllerProvider.notifier).restoreAll();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recycle bin restored')),
    );
  }

  Future<void> _permanentlyDeleteItem(
    BuildContext context,
    WidgetRef ref,
    RecycleBinItem item,
  ) async {
    final confirmed = await _confirmPermanentDelete(
      context,
      title: 'Delete permanently?',
      message:
          '${item.title} will be removed from this phone and marked deleted '
          'for sync. This cannot be undone.',
    );
    if (!confirmed) {
      return;
    }

    await ref
        .read(recycleBinControllerProvider.notifier)
        .permanentlyDeleteItem(item);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} permanently deleted')),
    );
  }

  Future<void> _emptyRecycleBin(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmPermanentDelete(
      context,
      title: 'Empty recycle bin?',
      message:
          'All deleted traders and entries will be permanently removed from '
          'this phone and marked deleted for sync. This cannot be undone.',
    );
    if (!confirmed) {
      return;
    }

    await ref.read(recycleBinControllerProvider.notifier).emptyRecycleBin();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recycle bin emptied')),
    );
  }

  Future<bool> _confirmPermanentDelete(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
