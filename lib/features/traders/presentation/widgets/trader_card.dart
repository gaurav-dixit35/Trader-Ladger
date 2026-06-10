import 'package:flutter/material.dart';

import '../../domain/trader.dart';

class TraderCard extends StatelessWidget {
  const TraderCard({
    required this.trader,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onCall,
    super.key,
  });

  final Trader trader;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasMobile = trader.mobileNumber?.trim().isNotEmpty == true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_initial),
        ),
        title: Text(
          trader.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: hasMobile ? Text(trader.mobileNumber!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMobile)
              IconButton(
                tooltip: 'Call trader',
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined),
              ),
            PopupMenuButton<_TraderAction>(
              tooltip: 'Trader actions',
              onSelected: (action) {
                switch (action) {
                  case _TraderAction.edit:
                    onEdit();
                    break;
                  case _TraderAction.delete:
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _TraderAction.edit,
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: _TraderAction.delete,
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
        onTap: onTap,
      ),
    );
  }

  String get _initial {
    final trimmed = trader.name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed[0].toUpperCase();
  }
}

enum _TraderAction { edit, delete }
