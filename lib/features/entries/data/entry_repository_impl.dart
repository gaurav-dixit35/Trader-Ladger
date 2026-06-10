import '../../../core/utils/id_generator.dart';
import '../../../database/sync_status.dart';
import '../domain/business_entry.dart';
import '../domain/entry_repository.dart';
import 'entry_dao.dart';

class EntryRepositoryImpl implements EntryRepository {
  const EntryRepositoryImpl({
    required this.entryDao,
    required this.idGenerator,
  });

  final EntryDao entryDao;
  final IdGenerator idGenerator;

  @override
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
    final normalizedBillNumber = billNumber.trim();
    if (traderId.trim().isEmpty) {
      throw ArgumentError.value(traderId, 'traderId', 'Trader is required.');
    }
    if (normalizedBillNumber.isEmpty) {
      throw ArgumentError.value(
        billNumber,
        'billNumber',
        'Bill number is required.',
      );
    }
    _validateAmounts(
      billAmount: billAmount,
      cashAmount: cashAmount,
      chequeAmount: chequeAmount,
    );

    final now = DateTime.now();
    final pendingAmount = BusinessEntry.calculatePending(
      billAmount: billAmount,
      cashAmount: cashAmount,
      chequeAmount: chequeAmount,
    );
    final entry = BusinessEntry(
      id: idGenerator.newId(),
      traderId: traderId,
      entryDate: entryDate,
      billNumber: normalizedBillNumber,
      billAmount: billAmount,
      cashAmount: cashAmount,
      chequeAmount: chequeAmount,
      chequeNumber: _normalizeOptional(chequeNumber),
      depositDate: depositDate,
      pendingAmount: pendingAmount,
      notes: _normalizeOptional(notes),
      paymentStatus: BusinessEntry.calculateStatus(
        pendingAmount,
        billAmount,
      ),
      isDeleted: false,
      syncStatus: SyncStatus.pendingCreate,
      createdAt: now,
      updatedAt: now,
    );

    await entryDao.insert(entry);
    return entry;
  }

  @override
  Future<List<BusinessEntry>> findAll() {
    return entryDao.findActive();
  }

  @override
  Future<BusinessEntry?> findById(String id) {
    return entryDao.findById(id);
  }

  @override
  Future<void> restoreEntry(String id) async {
    final entry = await entryDao.findById(id);
    if (entry == null) {
      return;
    }

    await entryDao.restore(
      id,
      restoredAt: DateTime.now(),
      syncStatus: _nextWriteStatus(entry.syncStatus).name,
    );
  }

  @override
  Future<List<BusinessEntry>> search(String query) {
    if (query.trim().isEmpty) {
      return findAll();
    }

    return entryDao.search(query);
  }

  @override
  Future<void> softDeleteEntry(String id) async {
    final entry = await entryDao.findById(id);
    if (entry == null) {
      return;
    }

    await entryDao.markDeleted(
      id,
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingDelete.name,
    );
  }

  @override
  Future<void> softDeleteEntries(Iterable<String> ids) {
    return entryDao.markManyDeleted(
      ids,
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingDelete.name,
    );
  }

  @override
  Future<int> softDeleteAllEntries() {
    return entryDao.markAllDeleted(
      deletedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingDelete.name,
    );
  }

  @override
  Future<BusinessEntry> updateEntry(BusinessEntry entry) async {
    final billNumber = entry.billNumber.trim();
    if (billNumber.isEmpty) {
      throw ArgumentError.value(
        entry.billNumber,
        'entry.billNumber',
        'Bill number is required.',
      );
    }
    _validateAmounts(
      billAmount: entry.billAmount,
      cashAmount: entry.cashAmount,
      chequeAmount: entry.chequeAmount,
    );

    final pendingAmount = BusinessEntry.calculatePending(
      billAmount: entry.billAmount,
      cashAmount: entry.cashAmount,
      chequeAmount: entry.chequeAmount,
    );
    final updated = entry.copyWith(
      billNumber: billNumber,
      chequeNumber: _normalizeOptional(entry.chequeNumber),
      clearChequeNumber: _normalizeOptional(entry.chequeNumber) == null,
      notes: _normalizeOptional(entry.notes),
      clearNotes: _normalizeOptional(entry.notes) == null,
      pendingAmount: pendingAmount,
      paymentStatus: BusinessEntry.calculateStatus(
        pendingAmount,
        entry.billAmount,
      ),
      syncStatus: _nextWriteStatus(entry.syncStatus),
      updatedAt: DateTime.now(),
    );

    await entryDao.update(updated);
    return updated;
  }

  void _validateAmounts({
    required int billAmount,
    required int cashAmount,
    required int chequeAmount,
  }) {
    if (billAmount < 0 || cashAmount < 0 || chequeAmount < 0) {
      throw ArgumentError('Amounts cannot be negative.');
    }
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
