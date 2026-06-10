class DashboardSummary {
  const DashboardSummary({
    required this.totalBillAmount,
    required this.totalCashAmount,
    required this.totalChequeAmount,
    required this.pendingAmount,
    required this.todayCollection,
    required this.weeklyCollection,
    required this.monthlyCollection,
    required this.upcomingDepositAmount,
    required this.upcomingDepositCount,
    required this.traderTotals,
  });

  final int totalBillAmount;
  final int totalCashAmount;
  final int totalChequeAmount;
  final int pendingAmount;
  final int todayCollection;
  final int weeklyCollection;
  final int monthlyCollection;
  final int upcomingDepositAmount;
  final int upcomingDepositCount;
  final List<TraderDashboardTotal> traderTotals;

  static const empty = DashboardSummary(
    totalBillAmount: 0,
    totalCashAmount: 0,
    totalChequeAmount: 0,
    pendingAmount: 0,
    todayCollection: 0,
    weeklyCollection: 0,
    monthlyCollection: 0,
    upcomingDepositAmount: 0,
    upcomingDepositCount: 0,
    traderTotals: [],
  );
}

class TraderDashboardTotal {
  const TraderDashboardTotal({
    required this.traderId,
    required this.traderName,
    required this.totalBillAmount,
    required this.pendingAmount,
  });

  final String traderId;
  final String traderName;
  final int totalBillAmount;
  final int pendingAmount;
}
