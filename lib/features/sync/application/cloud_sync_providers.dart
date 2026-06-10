import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../database/database_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../security/application/pin_lock_providers.dart';
import '../data/firestore_record_sync_service.dart';
import '../domain/cloud_sync_result.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreRecordSyncServiceProvider =
    Provider<FirestoreRecordSyncService>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  return FirestoreRecordSyncService(
    firestore: ref.watch(firebaseFirestoreProvider),
    localDatabase: ref.watch(localDatabaseProvider),
    secureStorage: ref.watch(secureStorageProvider),
    userId: user?.id,
  );
});

final cloudSyncControllerProvider =
    StateNotifierProvider<CloudSyncController, AsyncValue<CloudSyncResult?>>(
  (ref) {
    return CloudSyncController(
      syncService: ref.watch(firestoreRecordSyncServiceProvider),
      onDataChanged: () => notifyDataChanged(ref),
    );
  },
);

final cloudSyncBootstrapProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final pinState = ref.watch(pinLockControllerProvider);
  final isLoggedIn = authState.asData?.value != null;
  if (!isLoggedIn || !pinState.isUnlocked) {
    return;
  }

  final controller = ref.read(cloudSyncControllerProvider.notifier);
  unawaited(_runSilentSync(controller));

  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    unawaited(_runSilentSync(controller));
  });
  ref.onDispose(timer.cancel);
});

Future<void> _runSilentSync(CloudSyncController controller) async {
  try {
    await controller.syncNow(silent: true);
  } catch (_) {
    // Silent background sync retries on the next scheduled cycle.
  }
}

class CloudSyncController extends StateNotifier<AsyncValue<CloudSyncResult?>> {
  CloudSyncController({
    required this.syncService,
    required this.onDataChanged,
  })
      : super(const AsyncValue.data(null));

  final FirestoreRecordSyncService syncService;
  final void Function() onDataChanged;

  Future<CloudSyncResult> syncNow({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }

    try {
      final result = await syncService.syncNow();
      state = AsyncValue.data(result);
      if (result.pushedRecords > 0 || result.pulledRecords > 0) {
        onDataChanged();
      }
      return result;
    } catch (error, stackTrace) {
      if (!silent) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }
}
