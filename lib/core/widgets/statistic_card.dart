import 'package:flutter/material.dart';

import '../constants/app_layout.dart';

class StatisticCard extends StatelessWidget {
  const StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
    this.supportingText,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? supportingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colorScheme.primary),
                  const SizedBox(width: AppLayout.spacingSm),
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.spacingMd),
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (supportingText != null) ...[
                const SizedBox(height: AppLayout.spacingXs),
                Text(
                  supportingText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
