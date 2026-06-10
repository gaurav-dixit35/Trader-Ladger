import 'dart:math';

import '../../../database/database_value_converters.dart';
import '../../../database/sync_status.dart';
import '../../../models/payment_status.dart';

class BusinessEntry {
  const BusinessEntry({
    required this.id,
    required this.traderId,
    required this.entryDate,
    required this.billNumber,
    required this.billAmount,
    required this.cashAmount,
    required this.chequeAmount,
    required this.pendingAmount,
    required this.paymentStatus,
    required this.isDeleted,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.traderName,
    this.chequeNumber,
    this.depositDate,
    this.notes,
    this.deletedAt,
    this.remoteId,
  });

  final String id;
  final String traderId;
  final String? traderName;
  final DateTime entryDate;
  final String billNumber;
  final int billAmount;
  final int cashAmount;
  final int chequeAmount;
  final String? chequeNumber;
  final DateTime? depositDate;
  final int pendingAmount;
  final String? notes;
  final PaymentStatus paymentStatus;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? remoteId;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BusinessEntry.fromMap(Map<String, Object?> map) {
    return BusinessEntry(
      id: map['id']! as String,
      traderId: map['trader_id']! as String,
      traderName: map['trader_name'] as String?,
      entryDate: DatabaseValueConverters.millisToDateTime(
        map['entry_date']! as int,
      ),
      billNumber: map['bill_number']! as String,
      billAmount: map['bill_amount']! as int,
      cashAmount: map['cash_amount']! as int,
      chequeAmount: map['cheque_amount']! as int,
      chequeNumber: map['cheque_number'] as String?,
      depositDate: DatabaseValueConverters.nullableMillisToDateTime(
        map['deposit_date'] as int?,
      ),
      pendingAmount: map['pending_amount']! as int,
      notes: map['notes'] as String?,
      paymentStatus: PaymentStatus.fromName(map['payment_status']! as String),
      isDeleted: DatabaseValueConverters.intToBool(map['is_deleted']! as int),
      deletedAt: DatabaseValueConverters.nullableMillisToDateTime(
        map['deleted_at'] as int?,
      ),
      remoteId: map['remote_id'] as String?,
      syncStatus: SyncStatus.fromName(map['sync_status']! as String),
      createdAt: DatabaseValueConverters.millisToDateTime(
        map['created_at']! as int,
      ),
      updatedAt: DatabaseValueConverters.millisToDateTime(
        map['updated_at']! as int,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trader_id': traderId,
      'entry_date': DatabaseValueConverters.dateTimeToMillis(entryDate),
      'bill_number': billNumber,
      'bill_amount': billAmount,
      'cash_amount': cashAmount,
      'cheque_amount': chequeAmount,
      'cheque_number': chequeNumber,
      'deposit_date': DatabaseValueConverters.nullableDateTimeToMillis(
        depositDate,
      ),
      'pending_amount': pendingAmount,
      'notes': notes,
      'payment_status': paymentStatus.name,
      'is_deleted': DatabaseValueConverters.boolToInt(isDeleted),
      'deleted_at': DatabaseValueConverters.nullableDateTimeToMillis(deletedAt),
      'remote_id': remoteId,
      'sync_status': syncStatus.name,
      'created_at': DatabaseValueConverters.dateTimeToMillis(createdAt),
      'updated_at': DatabaseValueConverters.dateTimeToMillis(updatedAt),
    };
  }

  BusinessEntry copyWith({
    String? traderId,
    String? traderName,
    DateTime? entryDate,
    String? billNumber,
    int? billAmount,
    int? cashAmount,
    int? chequeAmount,
    String? chequeNumber,
    bool clearChequeNumber = false,
    DateTime? depositDate,
    bool clearDepositDate = false,
    int? pendingAmount,
    String? notes,
    bool clearNotes = false,
    PaymentStatus? paymentStatus,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? remoteId,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return BusinessEntry(
      id: id,
      traderId: traderId ?? this.traderId,
      traderName: traderName ?? this.traderName,
      entryDate: entryDate ?? this.entryDate,
      billNumber: billNumber ?? this.billNumber,
      billAmount: billAmount ?? this.billAmount,
      cashAmount: cashAmount ?? this.cashAmount,
      chequeAmount: chequeAmount ?? this.chequeAmount,
      chequeNumber:
          clearChequeNumber ? null : chequeNumber ?? this.chequeNumber,
      depositDate: clearDepositDate ? null : depositDate ?? this.depositDate,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      notes: clearNotes ? null : notes ?? this.notes,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      remoteId: remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int calculatePending({
    required int billAmount,
    required int cashAmount,
    required int chequeAmount,
  }) {
    return max(0, billAmount - cashAmount - chequeAmount);
  }

  static PaymentStatus calculateStatus(int pendingAmount, int billAmount) {
    if (pendingAmount <= 0) {
      return PaymentStatus.paid;
    }
    if (pendingAmount >= billAmount) {
      return PaymentStatus.pending;
    }
    return PaymentStatus.partial;
  }
}
