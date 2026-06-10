import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_file_storage_service.dart';

final localFileStorageProvider = Provider<LocalFileStorageService>((ref) {
  return const LocalFileStorageService();
});
