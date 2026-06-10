import '../../../database/database_value_converters.dart';
import '../../../database/sync_status.dart';

class Trader {
  const Trader({
    required this.id,
    required this.name,
    required this.isDeleted,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.mobileNumber,
    this.notes,
    this.deletedAt,
    this.remoteId,
  });

  final String id;
  final String name;
  final String? mobileNumber;
  final String? notes;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? remoteId;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Trader.fromMap(Map<String, Object?> map) {
    return Trader(
      id: map['id']! as String,
      name: map['name']! as String,
      mobileNumber: map['mobile_number'] as String?,
      notes: map['notes'] as String?,
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
      'name': name,
      'mobile_number': mobileNumber,
      'notes': notes,
      'is_deleted': DatabaseValueConverters.boolToInt(isDeleted),
      'deleted_at': DatabaseValueConverters.nullableDateTimeToMillis(deletedAt),
      'remote_id': remoteId,
      'sync_status': syncStatus.name,
      'created_at': DatabaseValueConverters.dateTimeToMillis(createdAt),
      'updated_at': DatabaseValueConverters.dateTimeToMillis(updatedAt),
    };
  }

  Trader copyWith({
    String? id,
    String? name,
    String? mobileNumber,
    bool clearMobileNumber = false,
    String? notes,
    bool clearNotes = false,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? remoteId,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trader(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber:
          clearMobileNumber ? null : mobileNumber ?? this.mobileNumber,
      notes: clearNotes ? null : notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      remoteId: remoteId ?? this.remoteId,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
