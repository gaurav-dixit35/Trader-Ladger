class ReportFilter {
  const ReportFilter({
    this.traderId,
    this.startDate,
    this.endDate,
    this.pendingOnly = false,
  });

  final String? traderId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool pendingOnly;

  ReportFilter copyWith({
    String? traderId,
    bool clearTraderId = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? pendingOnly,
  }) {
    return ReportFilter(
      traderId: clearTraderId ? null : traderId ?? this.traderId,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      pendingOnly: pendingOnly ?? this.pendingOnly,
    );
  }
}
