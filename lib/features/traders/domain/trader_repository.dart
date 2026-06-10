import '../../../core/contracts/repository.dart';
import 'trader.dart';

abstract class TraderRepository implements Repository<Trader> {
  Future<Trader> createTrader({
    required String name,
    String? mobileNumber,
    String? notes,
  });

  Future<Trader> updateTrader(Trader trader);

  Future<void> softDeleteTrader(String id);

  Future<void> restoreTrader(String id);

  Future<List<Trader>> search(String query);
}
