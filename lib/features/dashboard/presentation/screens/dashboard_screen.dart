import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/statistic_card.dart';
import '../../../notifications/application/notification_providers.dart';
import '../../../reports/application/report_providers.dart';
import '../../../reports/domain/report_filter.dart';
import '../../application/dashboard_providers.dart';
import '../../domain/dashboard_summary.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.read(reminderSchedulerProvider).refreshSchedules();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: summaryState.when(
        data: (summary) => _DashboardContent(summary: summary),
        error: (error, stackTrace) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load dashboard',
          message: 'Please refresh the dashboard.',
          action: OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoute.entries.path),
        icon: const Icon(Icons.add),
        label: const Text('Entry'),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppLayout.spacingLg),
      children: [
        _HomeHeader(summary: summary),
        const SizedBox(height: AppLayout.spacingLg),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppLayout.tabletBreakpoint;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              mainAxisSpacing: AppLayout.spacingMd,
              crossAxisSpacing: AppLayout.spacingMd,
              childAspectRatio: isWide ? 1.45 : 1.12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatisticCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total',
                  value: CurrencyFormatter.inr(summary.totalBillAmount),
                  supportingText: 'All bills',
                  onTap: () => _openAllReports(context, ref),
                ),
                StatisticCard(
                  icon: Icons.payments_outlined,
                  label: 'Cash',
                  value: CurrencyFormatter.inr(summary.totalCashAmount),
                  supportingText: 'Received',
                ),
                StatisticCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Cheque',
                  value: CurrencyFormatter.inr(summary.totalChequeAmount),
                  supportingText: 'Collected',
                ),
                StatisticCard(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pending',
                  value: CurrencyFormatter.inr(summary.pendingAmount),
                  supportingText: 'Tap to view',
                  onTap: () => _openPendingReports(context, ref),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppLayout.spacingLg),
        const _SectionTitle(
          icon: Icons.calendar_today_outlined,
          title: 'Collections',
        ),
        const SizedBox(height: AppLayout.spacingSm),
        _CollectionSection(summary: summary),
        const SizedBox(height: AppLayout.spacingLg),
        const _SectionTitle(
          icon: Icons.event_available_outlined,
          title: 'Deposits',
        ),
        const SizedBox(height: AppLayout.spacingSm),
        _UpcomingDeposits(summary: summary),
        const SizedBox(height: AppLayout.spacingLg),
        const _SectionTitle(
          icon: Icons.groups_outlined,
          title: 'Trader Totals',
        ),
        const SizedBox(height: AppLayout.spacingSm),
        _TraderTotals(summary: summary),
      ],
    );
  }

  void _openAllReports(BuildContext context, WidgetRef ref) {
    ref.read(reportFilterProvider.notifier).state = const ReportFilter();
    context.push(AppRoute.reports.path);
  }

  void _openPendingReports(BuildContext context, WidgetRef ref) {
    ref.read(reportFilterProvider.notifier).state = const ReportFilter(
          pendingOnly: true,
        );
    context.push(AppRoute.reports.path);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(AppLayout.radiusSm),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppLayout.spacingMd),
                Expanded(
                  child: Text(
                    AppConstants.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spacingLg),
            Text(
              CurrencyFormatter.inr(summary.pendingAmount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppLayout.spacingXs),
            Text(
              '${summary.upcomingDepositCount} deposits upcoming',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
            ),
            const SizedBox(height: AppLayout.spacingMd),
            Wrap(
              spacing: AppLayout.spacingSm,
              runSpacing: AppLayout.spacingSm,
              children: [
                _HeaderPill(
                  icon: Icons.payments_outlined,
                  label: 'Cash ${CurrencyFormatter.inr(summary.totalCashAmount)}',
                ),
                _HeaderPill(
                  icon: Icons.fact_check_outlined,
                  label:
                      'Cheque ${CurrencyFormatter.inr(summary.totalChequeAmount)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppLayout.radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.spacingSm,
          vertical: AppLayout.spacingXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: AppLayout.spacingXs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppLayout.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _CollectionSection extends ConsumerWidget {
  const _CollectionSection({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          _SummaryTile(
            icon: Icons.today_outlined,
            label: 'Today collection',
            value: CurrencyFormatter.inr(summary.todayCollection),
            onTap: () => _openRange(context, ref, _todayRange()),
          ),
          const Divider(height: 1),
          _SummaryTile(
            icon: Icons.calendar_view_week_outlined,
            label: 'Weekly collection',
            value: CurrencyFormatter.inr(summary.weeklyCollection),
            onTap: () => _openRange(context, ref, _weekRange()),
          ),
          const Divider(height: 1),
          _SummaryTile(
            icon: Icons.calendar_month_outlined,
            label: 'Monthly collection',
            value: CurrencyFormatter.inr(summary.monthlyCollection),
            onTap: () => _openRange(context, ref, _monthRange()),
          ),
        ],
      ),
    );
  }

  void _openRange(BuildContext context, WidgetRef ref, DateTimeRange range) {
    ref.read(reportFilterProvider.notifier).state = ReportFilter(
          startDate: range.start,
          endDate: range.end,
        );
    context.push(AppRoute.reports.path);
  }

  DateTimeRange _todayRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: today, end: today);
  }

  DateTimeRange _weekRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday - 1));
    return DateTimeRange(start: start, end: today);
  }

  DateTimeRange _monthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }
}

class _UpcomingDeposits extends StatelessWidget {
  const _UpcomingDeposits({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: const Text('Upcoming deposits'),
        subtitle: Text('${summary.upcomingDepositCount} cheque deposits'),
        trailing: Text(
          CurrencyFormatter.inr(summary.upcomingDepositAmount),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TraderTotals extends StatelessWidget {
  const _TraderTotals({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.traderTotals.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.groups_outlined),
          title: Text('Trader-wise totals'),
          subtitle: Text('Trader totals will appear after entries are added.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (final trader in summary.traderTotals) ...[
            if (trader != summary.traderTotals.first) const Divider(height: 1),
            ListTile(
              title: Text(trader.traderName),
              subtitle: Text(
                'Total ${CurrencyFormatter.inr(trader.totalBillAmount)}',
              ),
              trailing: Text(
                CurrencyFormatter.inr(trader.pendingAmount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
