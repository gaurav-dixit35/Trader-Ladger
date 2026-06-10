import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GoogleDriveBackupService {
  const GoogleDriveBackupService({
    required this.googleSignIn,
    required this.expectedEmail,
  });

  static const latestBackupFileName = 'trader_ledger_latest_backup.zip';
  static const _scopes = [drive.DriveApi.driveFileScope];

  final GoogleSignIn googleSignIn;
  final String? expectedEmail;
  static Future<void>? _initializingGoogleSignIn;

  Future<String> uploadBackup(String localFilePath) async {
    final api = await _driveApi();
    final file = File(localFilePath);
    final existing = await _findLatestBackup(api);
    final metadata = drive.File()
      ..name = latestBackupFileName
      ..appProperties = {
        'app': 'trader_ledger_app',
        'type': 'latest_backup',
        if (expectedEmail != null) 'email': expectedEmail!.toLowerCase(),
      };
    final media = drive.Media(
      file.openRead(),
      await file.length(),
      contentType: 'application/zip',
    );

    if (existing?.id != null) {
      final updated = await api.files.update(
        metadata,
        existing!.id!,
        uploadMedia: media,
      );
      return updated.id ?? existing.id!;
    }

    final created = await api.files.create(
      metadata,
      uploadMedia: media,
    );
    return created.id ?? latestBackupFileName;
  }

  Future<String> downloadLatestBackup() async {
    final api = await _driveApi();
    final latest = await _findLatestBackup(api);
    final fileId = latest?.id;
    if (fileId == null) {
      throw StateError('No Google Drive backup found.');
    }

    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final directory = await getApplicationDocumentsDirectory();
    final restoreDirectory = Directory(p.join(directory.path, 'restores'));
    if (!await restoreDirectory.exists()) {
      await restoreDirectory.create(recursive: true);
    }

    final restorePath = p.join(
      restoreDirectory.path,
      'trader_ledger_drive_restore.zip',
    );
    final restoreFile = File(restorePath).openWrite();
    await media.stream.pipe(restoreFile);
    return restorePath;
  }

  Future<drive.DriveApi> _driveApi() async {
    if (expectedEmail == null || expectedEmail!.isEmpty) {
      throw StateError('Sign in before using Google Drive backup.');
    }

    await _ensureGoogleSignInInitialized();
    final account = await googleSignIn.attemptLightweightAuthentication() ??
        await googleSignIn.authenticate(scopeHint: _scopes);
    if (account.email.toLowerCase() != expectedEmail!.toLowerCase()) {
      await googleSignIn.signOut();
      throw StateError(
        'Use the same Google account as your Trader Ledger login.',
      );
    }

    final authorization =
        await account.authorizationClient.authorizationForScopes(_scopes) ??
            await account.authorizationClient.authorizeScopes(_scopes);
    final auth.AuthClient client = authorization.authClient(scopes: _scopes);
    return drive.DriveApi(client);
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _initializingGoogleSignIn ??= googleSignIn.initialize();
  }

  Future<drive.File?> _findLatestBackup(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: 'drive',
      q: "name = '$latestBackupFileName' and trashed = false and "
          "appProperties has { key='app' and value='trader_ledger_app' }",
      orderBy: 'modifiedTime desc',
      pageSize: 1,
      $fields: 'files(id,name,modifiedTime)',
    );

    final files = result.files ?? const [];
    if (files.isEmpty) {
      return null;
    }

    return files.first;
  }
}
