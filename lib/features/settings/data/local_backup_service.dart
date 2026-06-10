import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../database/database_constants.dart';
import '../../../database/local_database.dart';
import '../domain/backup_result.dart';

class LocalBackupService {
  const LocalBackupService({required this.localDatabase});

  final LocalDatabase localDatabase;
  static const _manifestFileName = 'manifest.json';

  static const _backupOrder = [
    DatabaseConstants.appSettingsTable,
    DatabaseConstants.tradersTable,
    DatabaseConstants.entriesTable,
    DatabaseConstants.entryImagesTable,
    DatabaseConstants.deletedRecordsTable,
    DatabaseConstants.syncQueueTable,
  ];

  static const _restoreDeleteOrder = [
    DatabaseConstants.syncQueueTable,
    DatabaseConstants.deletedRecordsTable,
    DatabaseConstants.entryImagesTable,
    DatabaseConstants.entriesTable,
    DatabaseConstants.tradersTable,
    DatabaseConstants.appSettingsTable,
  ];

  Future<BackupResult> createBackup() async {
    final db = await localDatabase.database;
    final createdAt = DateTime.now();
    final tables = <String, List<Map<String, Object?>>>{};
    var recordCount = 0;

    for (final table in _backupOrder) {
      final rows = await db.query(table);
      tables[table] = rows;
      recordCount += rows.length;
    }

    final imageFiles = await _collectEntryImageFiles(
      tables[DatabaseConstants.entryImagesTable] ?? const [],
    );
    final manifest = {
      'app': 'Trader Ledger App',
      'schemaVersion': DatabaseConstants.version,
      'createdAt': createdAt.toIso8601String(),
      'tables': tables,
      'files': {
        'entryImages': _manifestImageFiles(imageFiles),
      },
    };

    final file = await _createBackupFile(createdAt);
    await _writeZipBackup(
      file: file,
      manifest: manifest,
      imageFiles: imageFiles,
    );

    return BackupResult(
      filePath: file.path,
      createdAt: createdAt,
      tableCount: tables.length,
      recordCount: recordCount,
    );
  }

  Future<void> restoreFromFile(String filePath) async {
    final file = File(filePath);
    final payload = await _readBackupManifest(file);
    final schemaVersion = payload['schemaVersion'] as int?;
    if (schemaVersion != DatabaseConstants.version) {
      throw StateError('Unsupported backup schema version.');
    }

    final tables = Map<String, Object?>.from(payload['tables'] as Map);
    final imageFiles = _entryImageFilesById(payload);
    await localDatabase.transaction((transaction) async {
      for (final table in _restoreDeleteOrder) {
        await transaction.delete(table);
      }

      for (final table in _backupOrder) {
        final rows = tables[table] as List<dynamic>? ?? const [];
        for (final row in rows) {
          final restoredRow = Map<String, Object?>.from(row as Map);
          if (table == DatabaseConstants.entryImagesTable) {
            await _restoreEntryImageFile(restoredRow, imageFiles, file);
          }

          await transaction.insert(
            table,
            restoredRow,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> _writeZipBackup({
    required File file,
    required Map<String, Object?> manifest,
    required List<Map<String, Object?>> imageFiles,
  }) async {
    final archive = Archive();
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
      ArchiveFile(_manifestFileName, manifestBytes.length, manifestBytes),
    );

    for (final imageFile in imageFiles) {
      final archivePath = imageFile['archivePath'] as String?;
      final sourcePath = imageFile['sourcePath'] as String?;
      if (archivePath == null || sourcePath == null) {
        continue;
      }

      final bytes = await File(sourcePath).readAsBytes();
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('Could not create backup zip.');
    }

    await file.writeAsBytes(zipBytes, flush: true);
  }

  Future<Map<String, Object?>> _readBackupManifest(File file) async {
    if (p.extension(file.path).toLowerCase() != '.zip') {
      return Map<String, Object?>.from(
        jsonDecode(await file.readAsString()) as Map,
      );
    }

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final manifestFile = archive.findFile(_manifestFileName);
    if (manifestFile == null || !manifestFile.isFile) {
      throw StateError('Backup manifest is missing.');
    }

    return Map<String, Object?>.from(
      jsonDecode(utf8.decode(_archiveFileBytes(manifestFile))) as Map,
    );
  }

  Future<List<Map<String, Object?>>> _collectEntryImageFiles(
    List<Map<String, Object?>> imageRows,
  ) async {
    final imageFiles = <Map<String, Object?>>[];

    for (final row in imageRows) {
      final imageId = row['id'] as String?;
      final entryId = row['entry_id'] as String?;
      final localPath = row['local_path'] as String?;
      if (imageId == null || entryId == null || localPath == null) {
        continue;
      }

      final file = File(localPath);
      if (!await file.exists()) {
        continue;
      }

      final archivePath = p.posix.join(
        'entry_images',
        entryId,
        '$imageId${_safeExtension(localPath)}',
      );
      imageFiles.add({
        'imageId': imageId,
        'entryId': entryId,
        'extension': _safeExtension(localPath),
        'archivePath': archivePath,
        'sourcePath': localPath,
      });
    }

    return imageFiles;
  }

  Map<String, Map<String, Object?>> _entryImageFilesById(
    Map<String, Object?> payload,
  ) {
    final files = payload['files'];
    if (files is! Map) {
      return const {};
    }

    final entryImages = files['entryImages'];
    if (entryImages is! List) {
      return const {};
    }

    final byId = <String, Map<String, Object?>>{};
    for (final imageFile in entryImages) {
      final fileMap = Map<String, Object?>.from(imageFile as Map);
      final imageId = fileMap['imageId'] as String?;
      if (imageId != null) {
        byId[imageId] = fileMap;
      }
    }

    return byId;
  }

  Future<void> _restoreEntryImageFile(
    Map<String, Object?> row,
    Map<String, Map<String, Object?>> imageFiles,
    File backupFile,
  ) async {
    final imageId = row['id'] as String?;
    final entryId = row['entry_id'] as String?;
    if (imageId == null || entryId == null) {
      return;
    }

    final imageFile = imageFiles[imageId];
    final archivePath = imageFile?['archivePath'] as String?;
    if (archivePath == null) {
      await _restoreLegacyBase64Image(row, imageFile);
      return;
    }

    final archive = ZipDecoder().decodeBytes(await backupFile.readAsBytes());
    final archivedImage = archive.findFile(archivePath);
    if (archivedImage == null || !archivedImage.isFile) {
      return;
    }

    final directory = await _entryImageDirectory(entryId);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final extension = imageFile?['extension'] as String?;
    final restoredPath = p.join(
      directory.path,
      '$imageId${_normalizedExtension(extension)}',
    );
    await File(restoredPath).writeAsBytes(
      _archiveFileBytes(archivedImage),
      flush: true,
    );
    row['local_path'] = restoredPath;
  }

  List<int> _archiveFileBytes(ArchiveFile file) {
    final content = file.content;
    if (content is List<int>) {
      return content;
    }

    throw StateError('Backup file content could not be read.');
  }

  List<Map<String, Object?>> _manifestImageFiles(
    List<Map<String, Object?>> imageFiles,
  ) {
    return imageFiles.map((imageFile) {
      final manifestImageFile = Map<String, Object?>.from(imageFile);
      manifestImageFile.remove('sourcePath');
      return manifestImageFile;
    }).toList(growable: false);
  }

  Future<void> _restoreLegacyBase64Image(
    Map<String, Object?> row,
    Map<String, Object?>? imageFile,
  ) async {
    final imageId = row['id'] as String?;
    final entryId = row['entry_id'] as String?;
    final contentBase64 = imageFile?['contentBase64'] as String?;
    if (imageId == null || entryId == null || contentBase64 == null) {
      return;
    }

    final directory = await _entryImageDirectory(entryId);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final extension = imageFile?['extension'] as String?;
    final restoredPath = p.join(
      directory.path,
      '$imageId${_normalizedExtension(extension)}',
    );
    await File(restoredPath).writeAsBytes(
      base64Decode(contentBase64),
      flush: true,
    );
    row['local_path'] = restoredPath;
  }

  Future<File> _createBackupFile(DateTime createdAt) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDirectory = Directory(p.join(directory.path, 'backups'));
    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }

    final timestamp = createdAt.millisecondsSinceEpoch;
    return File(
      p.join(backupDirectory.path, 'trader_ledger_backup_$timestamp.zip'),
    );
  }

  Future<Directory> _entryImageDirectory(String entryId) async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory(p.join(directory.path, 'entry_images', entryId));
  }

  String _safeExtension(String path) {
    final extension = p.extension(path).toLowerCase();
    return _normalizedExtension(extension);
  }

  String _normalizedExtension(String? extension) {
    if (extension == null || extension.isEmpty || !extension.startsWith('.')) {
      return '.jpg';
    }

    return extension;
  }
}
