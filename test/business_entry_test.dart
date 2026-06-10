// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import '../lib/features/entries/domain/business_entry.dart';
import '../lib/models/payment_status.dart';

void main() {
  group('BusinessEntry calculations', () {
    test('calculates pending amount from bill cash and cheque amounts', () {
      final pendingAmount = BusinessEntry.calculatePending(
        billAmount: 10000,
        cashAmount: 3000,
        chequeAmount: 2500,
      );

      expect(pendingAmount, 4500);
    });

    test('never returns a negative pending amount', () {
      final pendingAmount = BusinessEntry.calculatePending(
        billAmount: 1000,
        cashAmount: 1000,
        chequeAmount: 500,
      );

      expect(pendingAmount, 0);
    });

    test('calculates payment status from bill and pending amounts', () {
      expect(
        BusinessEntry.calculateStatus(0, 1000),
        PaymentStatus.paid,
      );
      expect(
        BusinessEntry.calculateStatus(1000, 1000),
        PaymentStatus.pending,
      );
      expect(
        BusinessEntry.calculateStatus(500, 1000),
        PaymentStatus.partial,
      );
    });

    test('treats overpayment as paid with zero pending amount', () {
      final pendingAmount = BusinessEntry.calculatePending(
        billAmount: 1000,
        cashAmount: 800,
        chequeAmount: 500,
      );

      expect(pendingAmount, 0);
      expect(
        BusinessEntry.calculateStatus(pendingAmount, 1000),
        PaymentStatus.paid,
      );
    });
  });
}
