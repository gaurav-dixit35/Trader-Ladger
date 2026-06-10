import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinLockService {
  const PinLockService(this._secureStorage);

  static const _pinHashKey = 'trader_ledger_pin_hash';
  static const _pinSaltKey = 'trader_ledger_pin_salt';

  final FlutterSecureStorage _secureStorage;

  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);
    return hash != null && salt != null;
  }

  Future<void> setPin(String pin) async {
    _validatePin(pin);
    final salt = _generateSalt();
    final hash = _hashPin(pin: pin, salt: salt);

    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    _validatePin(pin);
    final salt = await _secureStorage.read(key: _pinSaltKey);
    final savedHash = await _secureStorage.read(key: _pinHashKey);

    if (salt == null || savedHash == null) {
      return false;
    }

    return _hashPin(pin: pin, salt: salt) == savedHash;
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinSaltKey);
    await _secureStorage.delete(key: _pinHashKey);
  }

  void _validatePin(String pin) {
    if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
      throw ArgumentError('PIN must be 4 to 6 digits.');
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin({
    required String pin,
    required String salt,
  }) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
