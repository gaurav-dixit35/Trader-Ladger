enum PaymentStatus {
  paid,
  pending,
  partial;

  static PaymentStatus fromName(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}
