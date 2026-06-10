enum PinLockStatus {
  checking,
  setupRequired,
  locked,
  unlocked,
}

class PinLockState {
  const PinLockState({
    required this.status,
    this.errorMessage,
  });

  final PinLockStatus status;
  final String? errorMessage;

  bool get isChecking => status == PinLockStatus.checking;
  bool get requiresPin =>
      status == PinLockStatus.setupRequired || status == PinLockStatus.locked;
  bool get isUnlocked => status == PinLockStatus.unlocked;

  PinLockState copyWith({
    PinLockStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PinLockState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
