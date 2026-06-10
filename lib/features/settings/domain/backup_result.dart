class BackupResult {
  const BackupResult({
    required this.filePath,
    required this.createdAt,
    required this.tableCount,
    required this.recordCount,
  });

  final String filePath;
  final DateTime createdAt;
  final int tableCount;
  final int recordCount;
}
