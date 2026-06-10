import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_refresh_provider.dart';
import '../../../database/database_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/google_drive_backup_service.dart';
import '../data/local_backup_service.dart';
import '../domain/backup_result.dart';

final localBackupServiceProvider = Provider<LocalBackupService>((ref) {
  return LocalBackupService(localDatabase: ref.watch(localDatabaseProvider));
});

final googleDriveBackupServiceProvider = Provider<GoogleDriveBackupService>((
  ref,
) {
  final user = ref.watch(authStateProvider).asData?.value;
  return GoogleDriveBackupService(
    googleSignIn: ref.watch(googleSignInProvider),
    expectedEmail: user?.email,
  );
});

final backupControllerProvider =
    StateNotifierProvider<BackupController, AsyncValue<BackupResult?>>((ref) {
  return BackupController(
    localBackupService: ref.watch(localBackupServiceProvider),
    googleDriveBackupService: ref.watch(googleDriveBackupServiceProvider),
    onDataChanged: () => notifyDataChanged(ref),
  );
});

class BackupController extends StateNotifier<AsyncValue<BackupResult?>> {
  BackupController({
    required this.localBackupService,
    required this.googleDriveBackupService,
    required this.onDataChanged,
  }) : super(const AsyncValue.data(null));

  final LocalBackupService localBackupService;
  final GoogleDriveBackupService googleDriveBackupService;
  final void Function() onDataChanged;

  Future<BackupResult> createLocalBackup() async {
    state = const AsyncValue.loading();
    try {
      final result = await localBackupService.createBackup();
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<String> uploadGoogleDriveBackup() async {
    state = const AsyncValue.loading();
    try {
      final result = await localBackupService.createBackup();
      final driveFileId = await googleDriveBackupService.uploadBackup(
        result.filePath,
      );
      state = AsyncValue.data(result);
      return driveFileId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> restoreGoogleDriveBackup() async {
    state = const AsyncValue.loading();
    try {
      final filePath = await googleDriveBackupService.downloadLatestBackup();
      await localBackupService.restoreFromFile(filePath);
      state = const AsyncValue.data(null);
      onDataChanged();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
