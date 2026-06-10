import '../../../core/constants/app_constants.dart';
import '../../../core/services/local_file_storage_service.dart';
import '../../../core/utils/id_generator.dart';
import '../../../database/sync_status.dart';
import '../domain/entry_image.dart';
import '../domain/entry_image_repository.dart';
import 'entry_image_dao.dart';

class EntryImageLimitException implements Exception {
  const EntryImageLimitException();

  @override
  String toString() {
    return 'Maximum ${AppConstants.maxEntryImages} images are allowed per entry.';
  }
}

class EntryImageRepositoryImpl implements EntryImageRepository {
  const EntryImageRepositoryImpl({
    required this.imageDao,
    required this.fileStorageService,
    required this.idGenerator,
  });

  final EntryImageDao imageDao;
  final LocalFileStorageService fileStorageService;
  final IdGenerator idGenerator;

  @override
  Future<EntryImage> addImage({
    required String entryId,
    required String sourcePath,
  }) async {
    final activeCount = await imageDao.activeCount(entryId);
    if (activeCount >= AppConstants.maxEntryImages) {
      throw const EntryImageLimitException();
    }

    final imageId = idGenerator.newId();
    final localPath = await fileStorageService.copyEntryImage(
      sourcePath: sourcePath,
      entryId: entryId,
      imageId: imageId,
    );
    final now = DateTime.now();
    final image = EntryImage(
      id: imageId,
      entryId: entryId,
      localPath: localPath,
      sortOrder: await imageDao.nextSortOrder(entryId),
      isDeleted: false,
      syncStatus: SyncStatus.pendingCreate,
      createdAt: now,
      updatedAt: now,
    );

    await imageDao.insert(image);
    return image;
  }

  @override
  Future<List<EntryImage>> findByEntryId(String entryId) {
    return imageDao.findByEntryId(entryId);
  }

  @override
  Future<void> restoreImage(String id) async {
    final image = await imageDao.findById(id);
    if (image == null) {
      return;
    }

    final activeCount = await imageDao.activeCount(image.entryId);
    if (activeCount >= AppConstants.maxEntryImages) {
      throw const EntryImageLimitException();
    }

    await imageDao.restore(
      id,
      restoredAt: DateTime.now(),
      syncStatus: _nextWriteStatus(image.syncStatus).name,
    );
  }

  @override
  Future<void> softDeleteImage(String id) async {
    final image = await imageDao.findById(id);
    if (image == null) {
      return;
    }

    await imageDao.markDeleted(
      id,
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingDelete.name,
    );
  }

  SyncStatus _nextWriteStatus(SyncStatus current) {
    if (current == SyncStatus.pendingCreate) {
      return SyncStatus.pendingCreate;
    }

    return SyncStatus.pendingUpdate;
  }
}
