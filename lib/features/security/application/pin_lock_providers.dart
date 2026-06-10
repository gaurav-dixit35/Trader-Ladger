import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/pin_lock_service.dart';
import '../domain/pin_lock_state.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final pinLockServiceProvider = Provider<PinLockService>((ref) {
  return PinLockService(ref.watch(secureStorageProvider));
});

final pinLockControllerProvider =
    StateNotifierProvider<PinLockController, PinLockState>((ref) {
  final controller = PinLockController(
    service: ref.watch(pinLockServiceProvider),
  );
  controller.load();
  return controller;
});

class PinLockController extends StateNotifier<PinLockState> {
  PinLockController({required this.service})
      : super(const PinLockState(status: PinLockStatus.checking));

  final PinLockService service;

  Future<void> load() async {
    state = const PinLockState(status: PinLockStatus.checking);
    final hasPin = await service.hasPin();
    state = PinLockState(
      status: hasPin ? PinLockStatus.locked : PinLockStatus.setupRequired,
    );
  }

  Future<bool> setPin({
    required String pin,
    required String confirmPin,
  }) async {
    if (pin != confirmPin) {
      state = state.copyWith(errorMessage: 'PIN does not match.');
      return false;
    }

    try {
      await service.setPin(pin);
      state = const PinLockState(status: PinLockStatus.unlocked);
      return true;
    } on ArgumentError catch (error) {
      state = state.copyWith(errorMessage: error.message.toString());
      return false;
    }
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    if (newPin != confirmPin) {
      state = state.copyWith(errorMessage: 'New PIN does not match.');
      return false;
    }

    try {
      final isCurrentPinValid = await service.verifyPin(currentPin);
      if (!isCurrentPinValid) {
        state = state.copyWith(errorMessage: 'Current PIN is incorrect.');
        return false;
      }

      await service.setPin(newPin);
      state = const PinLockState(status: PinLockStatus.unlocked);
      return true;
    } on ArgumentError catch (error) {
      state = state.copyWith(errorMessage: error.message.toString());
      return false;
    }
  }

  Future<bool> unlock(String pin) async {
    try {
      final isValid = await service.verifyPin(pin);
      if (!isValid) {
        state = state.copyWith(errorMessage: 'Incorrect PIN.');
        return false;
      }

      state = const PinLockState(status: PinLockStatus.unlocked);
      return true;
    } on ArgumentError catch (error) {
      state = state.copyWith(errorMessage: error.message.toString());
      return false;
    }
  }

  Future<void> lockIfPinSet() async {
    final hasPin = await service.hasPin();
    if (!hasPin) {
      state = const PinLockState(status: PinLockStatus.setupRequired);
      return;
    }

    state = const PinLockState(status: PinLockStatus.locked);
  }
}
