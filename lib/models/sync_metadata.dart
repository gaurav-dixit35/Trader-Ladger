import '../database/sync_status.dart';

class SyncMetadata {
  const SyncMetadata({
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
  });

  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? remoteId;
}
