import '../../../core/contracts/repository.dart';
import 'business_entry.dart';

abstract class EntryRepository implements Repository<BusinessEntry> {
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
  });

  Future<BusinessEntry> updateEntry(BusinessEntry entry);

  Future<void> softDeleteEntry(String id);

  Future<void> softDeleteEntries(Iterable<String> ids);

  Future<int> softDeleteAllEntries();

  Future<void> restoreEntry(String id);

  Future<List<BusinessEntry>> search(String query);
}
