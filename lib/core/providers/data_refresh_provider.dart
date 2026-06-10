import 'package:flutter_riverpod/flutter_riverpod.dart';

final dataRefreshProvider = StateProvider<int>((ref) => 0);

void notifyDataChanged(Ref ref) {
  ref.read(dataRefreshProvider.notifier).state++;
}
