import '../../../database/database_value_converters.dart';
import '../../../database/sync_status.dart';

class EntryImage {
  const EntryImage({
    required this.id,
    required this.entryId,
    required this.localPath,
    required this.sortOrder,
    required this.isDeleted,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.remotePath,
    this.deletedAt,
    this.remoteId,
  });

  final String id;
  final String entryId;
  final String localPath;
  final String? remotePath;
  final int sortOrder;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? remoteId;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EntryImage.fromMap(Map<String, Object?> map) {
    return EntryImage(
      id: map['id']! as String,
      entryId: map['entry_id']! as String,
      localPath: map['local_path']! as String,
      remotePath: map['remote_path'] as String?,
      sortOrder: map['sort_order']! as int,
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
      'entry_id': entryId,
      'local_path': localPath,
      'remote_path': remotePath,
      'sort_order': sortOrder,
      'is_deleted': DatabaseValueConverters.boolToInt(isDeleted),
      'deleted_at': DatabaseValueConverters.nullableDateTimeToMillis(deletedAt),
      'remote_id': remoteId,
      'sync_status': syncStatus.name,
      'created_at': DatabaseValueConverters.dateTimeToMillis(createdAt),
      'updated_at': DatabaseValueConverters.dateTimeToMillis(updatedAt),
    };
  }
}
