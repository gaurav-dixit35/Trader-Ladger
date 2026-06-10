import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/id_generator.dart';

final idGeneratorProvider = Provider<IdGenerator>((ref) {
  return IdGenerator();
});
