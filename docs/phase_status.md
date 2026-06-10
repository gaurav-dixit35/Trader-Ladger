# Trader Ledger App Phase Status

## Phase 1 - Project Foundation

Status: Completed.

Completed work:
- Replaced Flutter starter counter app.
- Added Riverpod root.
- Added GoRouter app navigation.
- Added Material 3 theme.
- Added dashboard, traders, entries, reports, settings, and login screens.
- Added reusable empty state and statistic card widgets.
- Added feature-first folder structure.

Verification note:
- Manual source review completed.
- `flutter pub get` completed after dependencies were added.
- Full automated Flutter checks previously hung in this environment, so Phase 2
  uses bounded verification commands.

## Phase 2 - Offline Database Foundation

Status: Completed.

Completed work:
- Added SQLite dependency plan to `pubspec.yaml`.
- Added local database constants.
- Added v1 SQLite migration skeleton.
- Added local database open/close/transaction service.
- Added Riverpod database providers.
- Added base DAO and repository contracts.
- Added sync and payment status models.
- Added database value converters.
- Added database health check provider.
- Added UUID id generator.
- Added database schema notes.

Verification note:
- `flutter pub get` completed after removing `path_provider` from Phase 2.
- `path_provider` is deferred to the image/file phase to avoid unnecessary
  Windows plugin symlink setup during database work.
- Source review completed for Phase 2 database files.
- Local Dart/Flutter commands are hanging in this shell, even `dart --version`.
  Automated analyzer/test verification must be rerun once the local toolchain
  responds normally.

## Phase 3 - Trader Management

Status: Completed.

Completed work:
- Added trader domain model.
- Added trader repository contract.
- Added SQLite trader DAO.
- Added repository implementation.
- Added Riverpod trader providers and list controller.
- Added trader list UI with offline search.
- Added add/edit trader form.
- Added soft delete with undo restore.
- Added trader profile route and screen.
- Added repository-level trader name validation.

Verification note:
- Manual source review completed for Phase 3 files.
- Analyzer cleanup applied for migration dead code and constructor lint items.
- Removed final unused trader DAO import reported by analyzer.

## Phase 4 - Entry Management

Status: Completed.

Completed work:
- Added entry domain model with pending amount and payment status calculations.
- Added entry repository contract.
- Added SQLite entry DAO with trader joins for list/search.
- Added repository implementation with validation and soft delete support.
- Added Riverpod entry providers and list controller.
- Added entry list UI with offline search.
- Added add/edit entry form for bill, cash, cheque, deposit date, and notes.
- Added soft delete with undo restore.

Verification note:
- Source review completed for Phase 4 files.
- Replaced deprecated `DropdownButtonFormField.value` with `initialValue`.

## Phase 5 - Image Management

Status: Completed pending local plugin setup verification.

Completed work:
- Added `image_picker` and `path_provider` dependencies.
- Added image picker service for camera and gallery.
- Added local file storage service for app-controlled proof image copies.
- Added entry image domain model.
- Added entry image repository contract.
- Added SQLite entry image DAO.
- Added repository implementation with max 15 image enforcement.
- Added Riverpod image providers and controller.
- Added entry detail screen.
- Added proof image section with camera/gallery actions, preview grid, delete,
  and undo restore.
- Wired entry cards to open entry details.

Verification note:
- `flutter pub get` currently fails on Windows plugin symlink setup until
  Developer Mode is enabled.
- Enable Developer Mode, rerun `flutter pub get`, then run
  `flutter analyze --no-pub` and `flutter test --no-pub`.

## Phase 6 - Search And Dashboard

Status: Completed pending local plugin setup verification.

Completed work:
- Added dashboard summary model.
- Added SQLite dashboard DAO for offline calculations.
- Added dashboard repository and Riverpod providers.
- Replaced static dashboard values with local database calculations.
- Added total bill, cash, cheque, and pending cards.
- Added today, weekly, and monthly collection summaries.
- Added upcoming cheque deposit summary.
- Added trader-wise total and pending summary list.

Verification note:
- Source review completed for Phase 6 files.
- Full verification is still blocked until Phase 5 plugin setup completes:
  enable Developer Mode, rerun `flutter pub get`, then run analyzer/tests.

## Phase 7 - Reports, Export, And Sharing

Status: Completed pending local plugin setup verification.

Completed work:
- Added report filter model.
- Added report rows and summary model.
- Added SQLite report DAO.
- Added report repository.
- Added PDF export service.
- Added Excel export service.
- Added Android share-sheet sharing for exported files.
- Replaced reports placeholder screen with real local report data.
- Added date range filter and clear filter actions.

Verification note:
- Full verification is still blocked until Windows Developer Mode is enabled
  for plugin symlinks, because reports use `share_plus` and earlier phases use
  image/file plugins.

## Phase 8 - Authentication And PIN Security

Status: Completed pending local analyzer/test.

Reason for early start:
- Firebase project details and the approved Gmail account were provided before
  reports/export work.

Completed work:
- Added Firebase Core/Auth and Google Sign-In dependencies.
- Added Firebase options scaffold from the provided Firebase project values.
- Added approved Gmail guard for `user@example.com`.
- Added auth domain model and repository contract.
- Added Firebase auth repository implementation.
- Added Riverpod auth providers.
- Added login screen behavior for Google sign-in.
- Added route protection so unauthenticated users are sent to login.
- Added logout action in settings.
- Updated security scope to PIN-only.
- Added secure PIN storage with salted hash.
- Added PIN setup and unlock screen.
- Added route protection for PIN setup/unlock.
- Added app lifecycle locking when app is paused/inactive.
- Added manual "Lock app now" action in settings.

Verification note:
- Android Firebase configuration is completed in Phase 11.
- Developer Mode has been enabled and dependency resolution was run
  successfully.
- User will run `flutter analyze --no-pub` and `flutter test --no-pub`; Codex
  should not run those commands automatically.

## Phase 9 - Reminders And Notifications

Status: Completed pending local analyzer/test.

Completed work:
- Added local notification dependency.
- Added notification initialization service.
- Added cheque deposit reminder query.
- Added pending payment reminder query.
- Added reminder scheduler that replaces scheduled reminders from local data.
- Added reminder refresh action in settings.
- Dashboard refresh now also refreshes reminder schedules.

Verification note:
- User will run `flutter pub get`, `flutter analyze --no-pub`, and
  `flutter test --no-pub`.

## Phase 10 - Backup, Restore, And Cloud Backup Foundation

Status: Completed pending local analyzer/test and Firebase Storage setup.

Completed work:
- Added Firebase Storage dependency for cloud backup files.
- Added local `backup.zip` service for all SQLite tables.
- Added proof image file contents into backup zip snapshots.
- Added backup metadata result model.
- Added transaction-based restore from backup file.
- Restore now recreates proof image files under app-controlled storage.
- Added Firebase Storage upload for dated backups and `backups/latest.zip`.
- Added Firebase Storage download for latest cloud restore.
- Added Riverpod backup controller.
- Replaced the settings placeholder with real backup actions.
- Added restore confirmation before replacing local records.

Verification note:
- User will run `flutter pub get`, `flutter analyze --no-pub`, and
  `flutter test --no-pub`.
- Cloud backup requires Firebase Storage to be enabled in the client Firebase
  project.
- Android Firebase configuration is completed in Phase 11.

## Phase 11 - Android Firebase, Drive Backup, Voice Search, And Recovery

Status: Completed pending local analyzer/test and device verification.

Completed work:
- Added Google Services Gradle plugin wiring for Android.
- Aligned Android Gradle Plugin to 8.13.2 and Gradle wrapper to 8.13 so
  Kotlin-based Flutter plugins compile on the current Android build path.
- Copied `google-services.json` into `android/app/`.
- Updated Android package/application id to `com.traderledger.app`.
- Updated Android Firebase options from the Android Firebase config.
- Added Trader Ledger App launcher label.
- Generated Android launcher icons from `others/logo.png`.
- Added repeatable `flutter_launcher_icons` config.
- Added Google Drive app-data backup upload and restore.
- Added the narrow Google Drive AppData scope to the approved Gmail sign-in.
- Added Google Drive backup and restore actions in settings.
- Added voice search support for traders and entries.
- Added Android microphone permission for voice search.
- Added Recycle Bin screen for deleted traders and entries.
- Added restore single item and restore all actions for the recycle bin.
- Added soft delete all entries action that moves entries to recycle bin.

## Phase 12 - Trader Workflow, Tables, Branding, And Dashboard Drilldowns

Status: Completed pending local `flutter pub get`, analyzer, and device run.

Completed work:
- Traders are now the default post-splash page.
- PIN lock no longer triggers on every app pause/resume, so camera, gallery,
  Google auth, and app switching do not repeatedly force unlock.
- Added splash screen with Trader Ledger App logo and Trader Ledger App branding.
- Added Trader Ledger App logo/title branding across primary app bars.
- Added reusable Excel-style entry report table with serial numbers, sorting,
  row selection, and delete-selected-to-recycle-bin.
- Replaced report row cards with the table view.
- Trader profile now shows trader-wise entries in the same table format.
- Trader profile now supports creating an entry directly for that trader.
- Entry create/edit forms now support selecting proof images before saving.
- Dashboard today/week/month collection rows now open filtered report details.
- Dashboard total and pending cards now open report details.
- Excel-style tables and exports now include weekday and month columns.
- Report PDF/Excel export now includes Trader Ledger App branding and totals.
- Added print action for PDF report output.
- Added Android permissions for camera, notifications, images, and voice search.

Verification note:
- User will run Flutter commands manually.

Verification note:
- User will run `flutter pub get`, `flutter analyze --no-pub`, and
  `flutter test --no-pub`.
- SHA-1 and SHA-256 fingerprints have been provided for this Android package.
- Google Drive backup uses the approved Gmail account:
  `user@example.com`.
