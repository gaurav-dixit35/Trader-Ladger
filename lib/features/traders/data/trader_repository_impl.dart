import '../../../core/utils/id_generator.dart';
import '../../../database/sync_status.dart';
import '../domain/trader.dart';
import '../domain/trader_repository.dart';
import 'trader_dao.dart';

class TraderRepositoryImpl implements TraderRepository {
  const TraderRepositoryImpl({
    required this.traderDao,
    required this.idGenerator,
  });

  final TraderDao traderDao;
  final IdGenerator idGenerator;

  @override
  Future<Trader> createTrader({
    required String name,
    String? mobileNumber,
    String? notes,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Trader name is required.');
    }

    final now = DateTime.now();
    final trader = Trader(
      id: idGenerator.newId(),
      name: normalizedName,
      mobileNumber: _normalizeOptional(mobileNumber),
      notes: _normalizeOptional(notes),
      isDeleted: false,
      syncStatus: SyncStatus.pendingCreate,
      createdAt: now,
      updatedAt: now,
    );

    await traderDao.insert(trader);
    return trader;
  }

  @override
  Future<List<Trader>> findAll() {
    return traderDao.findActive();
  }

  @override
  Future<Trader?> findById(String id) {
    return traderDao.findById(id);
  }

  @override
  Future<void> restoreTrader(String id) async {
    final trader = await traderDao.findById(id);
    if (trader == null) {
      return;
    }

    await traderDao.restoreWithEntries(
      id,
      restoredAt: DateTime.now(),
      syncStatus: _nextWriteStatus(trader.syncStatus).name,
      originalDeletedAt: trader.deletedAt,
    );
  }

  @override
  Future<List<Trader>> search(String query) {
    if (query.trim().isEmpty) {
      return findAll();
    }

    return traderDao.search(query);
  }

  @override
  Future<void> softDeleteTrader(String id) async {
    final trader = await traderDao.findById(id);
    if (trader == null) {
      return;
    }

    await traderDao.markDeletedWithEntries(
      id,
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingDelete.name,
    );
  }

  @override
  Future<Trader> updateTrader(Trader trader) async {
    final normalizedName = trader.name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        trader.name,
        'trader.name',
        'Trader name is required.',
      );
    }

    final updated = trader.copyWith(
      name: normalizedName,
      mobileNumber: _normalizeOptional(trader.mobileNumber),
      notes: _normalizeOptional(trader.notes),
      syncStatus: _nextWriteStatus(trader.syncStatus),
      updatedAt: DateTime.now(),
    );

    await traderDao.update(updated);
    return updated;
  }

  SyncStatus _nextWriteStatus(SyncStatus current) {
    if (current == SyncStatus.pendingCreate) {
      return SyncStatus.pendingCreate;
    }

    return SyncStatus.pendingUpdate;
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
