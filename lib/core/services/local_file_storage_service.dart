import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileStorageService {
  const LocalFileStorageService();

  Future<String> copyEntryImage({
    required String sourcePath,
    required String entryId,
    required String imageId,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(
      p.join(documentsDirectory.path, 'entry_images', entryId),
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath).toLowerCase();
    final destinationPath = p.join(imageDirectory.path, '$imageId$extension');

    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
