import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../database/database_providers.dart';
import '../data/recycle_bin_dao.dart';
import '../domain/recycle_bin_item.dart';

final recycleBinDaoProvider = Provider<RecycleBinDao>((ref) {
  return RecycleBinDao(ref.watch(localDatabaseProvider));
});

final recycleBinControllerProvider =
    StateNotifierProvider<RecycleBinController, AsyncValue<List<RecycleBinItem>>>(
  (ref) {
    final controller = RecycleBinController(
      recycleBinDao: ref.watch(recycleBinDaoProvider),
      onDataChanged: () => notifyDataChanged(ref),
    );
    ref.listen<int>(dataRefreshProvider, (previous, next) {
      if (previous != null) {
        controller.load();
      }
    });
    controller.load();
    return controller;
  },
);

class RecycleBinController
    extends StateNotifier<AsyncValue<List<RecycleBinItem>>> {
  RecycleBinController({
    required this.recycleBinDao,
    required this.onDataChanged,
  })
      : super(const AsyncValue.loading());

  final RecycleBinDao recycleBinDao;
  final void Function() onDataChanged;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(recycleBinDao.findDeletedItems);
  }

  Future<void> restoreItem(RecycleBinItem item) async {
    await recycleBinDao.restoreItem(item);
    await load();
    onDataChanged();
  }

  Future<void> restoreAll() async {
    await recycleBinDao.restoreAll();
    await load();
    onDataChanged();
  }

  Future<void> permanentlyDeleteItem(RecycleBinItem item) async {
    await recycleBinDao.permanentlyDeleteItem(item);
    await load();
    onDataChanged();
  }

  Future<void> emptyRecycleBin() async {
    await recycleBinDao.emptyRecycleBin();
    await load();
    onDataChanged();
  }
}
