class CloudSyncResult {
  const CloudSyncResult({
    required this.pushedRecords,
    required this.pulledRecords,
    required this.syncedAt,
  });

  final int pushedRecords;
  final int pulledRecords;
  final DateTime syncedAt;

  int get totalRecords => pushedRecords + pulledRecords;
}
