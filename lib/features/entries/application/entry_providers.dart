import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../core/providers/id_generator_provider.dart';
import '../../../database/database_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../../notifications/data/reminder_scheduler.dart';
import '../data/entry_dao.dart';
import '../data/entry_repository_impl.dart';
import '../domain/business_entry.dart';
import '../domain/entry_repository.dart';

final entryDaoProvider = Provider<EntryDao>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return EntryDao(localDatabase);
});

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepositoryImpl(
    entryDao: ref.watch(entryDaoProvider),
    idGenerator: ref.watch(idGeneratorProvider),
  );
});

final entryListControllerProvider =
    StateNotifierProvider<EntryListController, AsyncValue<List<BusinessEntry>>>(
  (ref) {
    final controller = EntryListController(
      repository: ref.watch(entryRepositoryProvider),
      reminderScheduler: ref.watch(reminderSchedulerProvider),
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

final entryDetailProvider = FutureProvider.family<BusinessEntry?, String>((
  ref,
  entryId,
) {
  ref.watch(dataRefreshProvider);
  final repository = ref.watch(entryRepositoryProvider);
  return repository.findById(entryId);
});

class EntryListController extends StateNotifier<AsyncValue<List<BusinessEntry>>> {
  EntryListController({
    required this.repository,
    required this.reminderScheduler,
    required this.onDataChanged,
  })
      : super(const AsyncValue.loading());

  final EntryRepository repository;
  final ReminderScheduler reminderScheduler;
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

  Future<BusinessEntry> createEntry({
    required String traderId,
    required DateTime entryDate,
    required String billNumber,
    required int billAmount,
    required int cashAmount,
    required int chequeAmount,
    String? chequeNumber,
    DateTime? depositDate,
    String? notes,
  }) async {
    final entry = await repository.createEntry(
      traderId: traderId,
      entryDate: entryDate,
      billNumber: billNumber,
      billAmount: billAmount,
      cashAmount: cashAmount,
      chequeAmount: chequeAmount,
      chequeNumber: chequeNumber,
      depositDate: depositDate,
      notes: notes,
    );
    await load();
    await reminderScheduler.refreshSchedules();
    onDataChanged();
    return entry;
  }

  Future<void> updateEntry(BusinessEntry entry) async {
    await repository.updateEntry(entry);
    await load();
    await reminderScheduler.refreshSchedules();
    onDataChanged();
  }

  Future<void> deleteEntry(String id) async {
    await repository.softDeleteEntry(id);
    await load();
    await reminderScheduler.refreshSchedules();
    onDataChanged();
  }

  Future<void> deleteEntries(Iterable<String> ids) async {
    await repository.softDeleteEntries(ids);
    await load();
    await reminderScheduler.refreshSchedules();
    onDataChanged();
  }

  Future<int> deleteAllEntries() async {
    final count = await repository.softDeleteAllEntries();
    await load();
    await reminderScheduler.refreshSchedules();
    onDataChanged();
    return count;
  }

  Future<void> restoreEntry(String id) async {
    await repository.restoreEntry(id);
    await load();
    await reminderScheduler.refreshSchedules();
    onDataChanged();
  }

  Future<List<BusinessEntry>> _loadForCurrentQuery() {
    return repository.search(_query);
  }
}
