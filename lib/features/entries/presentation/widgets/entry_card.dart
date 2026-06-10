import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/business_entry.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final BusinessEntry entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                child: Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill ${entry.billNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.traderName ?? 'Unknown trader',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _EntryChip(
                          icon: Icons.calendar_today_outlined,
                          label: DateFormatter.displayDate(entry.entryDate),
                        ),
                        _EntryChip(
                          icon: Icons.payments_outlined,
                          label: CurrencyFormatter.inr(entry.billAmount),
                        ),
                        _EntryChip(
                          icon: Icons.pending_actions_outlined,
                          label:
                              'Pending ${CurrencyFormatter.inr(entry.pendingAmount)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_EntryAction>(
                tooltip: 'Entry actions',
                onSelected: (action) {
                  switch (action) {
                    case _EntryAction.edit:
                      onEdit();
                      break;
                    case _EntryAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _EntryAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _EntryAction.delete,
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      title: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

enum _EntryAction { edit, delete }
