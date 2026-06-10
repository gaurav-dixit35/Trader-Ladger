import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/providers/id_generator_provider.dart';
import '../../../core/providers/local_file_storage_provider.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../database/database_providers.dart';
import '../data/entry_image_dao.dart';
import '../data/entry_image_repository_impl.dart';
import '../domain/entry_image.dart';
import '../domain/entry_image_repository.dart';

final entryImageDaoProvider = Provider<EntryImageDao>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return EntryImageDao(localDatabase);
});

final entryImageRepositoryProvider = Provider<EntryImageRepository>((ref) {
  return EntryImageRepositoryImpl(
    imageDao: ref.watch(entryImageDaoProvider),
    fileStorageService: ref.watch(localFileStorageProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final entryImagesControllerProvider = StateNotifierProvider.family<
    EntryImagesController,
    AsyncValue<List<EntryImage>>,
    String>((ref, entryId) {
  final controller = EntryImagesController(
    entryId: entryId,
    repository: ref.watch(entryImageRepositoryProvider),
    onDataChanged: () => notifyDataChanged(ref),
  );
  ref.listen<int>(dataRefreshProvider, (previous, next) {
    if (previous != null) {
      controller.load();
    }
  });
  controller.load();
  return controller;
});

class EntryImagesController
    extends StateNotifier<AsyncValue<List<EntryImage>>> {
  EntryImagesController({
    required this.entryId,
    required this.repository,
    required this.onDataChanged,
  }) : super(const AsyncValue.loading());

  final String entryId;
  final EntryImageRepository repository;
  final void Function() onDataChanged;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.findByEntryId(entryId));
  }

  Future<void> addImage(String sourcePath) async {
    await repository.addImage(entryId: entryId, sourcePath: sourcePath);
    await load();
    onDataChanged();
  }

  Future<void> addFromPicker(
    Future<String?> Function(ImagePickerService picker) pick,
    ImagePickerService picker,
  ) async {
    final sourcePath = await pick(picker);
    if (sourcePath == null) {
      return;
    }

    await addImage(sourcePath);
  }

  Future<void> deleteImage(String id) async {
    await repository.softDeleteImage(id);
    await load();
    onDataChanged();
  }

  Future<void> restoreImage(String id) async {
    await repository.restoreImage(id);
    await load();
    onDataChanged();
  }
}
