import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/providers/id_generator_provider.dart';
import '../../../database/database_providers.dart';
import '../../../database/sync_status.dart';
import '../data/trader_dao.dart';
import '../data/trader_repository_impl.dart';
import '../domain/trader.dart';
import '../domain/trader_repository.dart';

final traderDaoProvider = Provider<TraderDao>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return TraderDao(localDatabase);
});

final traderRepositoryProvider = Provider<TraderRepository>((ref) {
  return TraderRepositoryImpl(
    traderDao: ref.watch(traderDaoProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final traderListControllerProvider =
    StateNotifierProvider<TraderListController, AsyncValue<List<Trader>>>(
  (ref) {
    final controller = TraderListController(
      repository: ref.watch(traderRepositoryProvider),
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

final traderDetailProvider = FutureProvider.family<Trader?, String>((
  ref,
  traderId,
) {
  ref.watch(dataRefreshProvider);
  final repository = ref.watch(traderRepositoryProvider);
  return repository.findById(traderId);
});

class TraderListController extends StateNotifier<AsyncValue<List<Trader>>> {
  TraderListController({
    required this.repository,
    required this.onDataChanged,
  })
      : super(const AsyncValue.loading());

  final TraderRepository repository;
  final void Function() onDataChanged;
  String _query = '';

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadForCurrentQuery);
  }

  Future<void> search(String query) async {
    _query = query;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadForCurrentQuery);
  }

  Future<void> createTrader({
    required String name,
    String? mobileNumber,
    String? notes,
  }) async {
    await repository.createTrader(
      name: name,
      mobileNumber: mobileNumber,
      notes: notes,
    );
    await load();
    onDataChanged();
  }

  Future<void> updateTrader(Trader trader) async {
    await repository.updateTrader(trader);
    await load();
    onDataChanged();
  }

  Future<void> deleteTrader(String id) async {
    await repository.softDeleteTrader(id);
    await load();
    onDataChanged();
  }

  Future<void> restoreTrader(String id) async {
    await repository.restoreTrader(id);
    await load();
    onDataChanged();
  }

  Future<List<Trader>> _loadForCurrentQuery() {
    return repository.search(_query);
  }
}

extension TraderSyncStatusLabel on Trader {
  String get syncLabel {
    switch (syncStatus) {
      case SyncStatus.synced:
        return 'Updated';
      case SyncStatus.pendingCreate:
      case SyncStatus.pendingUpdate:
        return 'Saved';
      case SyncStatus.pendingDelete:
        return 'Moved to recycle bin';
      case SyncStatus.failed:
        return 'Saved';
    }
  }
}
