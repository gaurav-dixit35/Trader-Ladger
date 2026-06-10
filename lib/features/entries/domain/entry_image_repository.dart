import 'entry_image.dart';

abstract class EntryImageRepository {
  Future<List<EntryImage>> findByEntryId(String entryId);

  Future<EntryImage> addImage({
    required String entryId,
    required String sourcePath,
  });

  Future<void> softDeleteImage(String id);

  Future<void> restoreImage(String id);
}
