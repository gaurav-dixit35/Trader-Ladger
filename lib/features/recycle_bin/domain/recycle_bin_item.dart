enum RecycleBinItemType {
  trader,
  entry,
}

class RecycleBinItem {
  const RecycleBinItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.deletedAt,
  });

  final String id;
  final RecycleBinItemType type;
  final String title;
  final String subtitle;
  final DateTime deletedAt;
}
