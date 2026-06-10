# Trader Ledger App Development Plan

Trader Ledger App is an offline-first business operations app for Trader Ledger App. The
local database is the primary source of truth. Cloud services are secondary and
must only support backup, restore, and optional notifications.

## Phase 1 - Project Foundation

Objective: replace the starter Flutter app with a production-ready foundation.

Features covered:
- Feature-based clean architecture folder layout.
- Material 3 app theme.
- Riverpod app root.
- GoRouter navigation.
- Bottom navigation shell for Dashboard, Traders, Entries, Reports, Settings.
- Reusable empty state and statistic card widgets.
- No fake business records.

Packages:
- `flutter_riverpod`
- `go_router`
- `intl`

Architecture decisions:
- Keep `main.dart` minimal.
- Keep routing in `config`.
- Keep shared UI primitives in `core/widgets`.
- Keep feature screens inside `features/<feature>/presentation`.

Database planning:
- No tables are created in this phase.
- SQLite is selected for Phase 2 because Trader Ledger App needs relational records,
  aggregate reports, indexed offline search, soft deletes, and sync metadata.

Implementation approach:
- Build a stable app shell first.
- Keep action buttons wired visually, but leave business actions for later
  phases where repositories and local persistence exist.

## Phase 2 - Offline Database Foundation

Objective: establish reliable local persistence as the source of truth.

Features covered:
- SQLite database service.
- Versioned migrations.
- Base DAO/repository contracts.
- Soft-delete fields.
- Sync metadata fields.
- Created/updated timestamps.
- Indexes for search and reports.

Packages:
- `sqflite`
- `path`
- `uuid`

Database planning:
- `traders`
- `entries`
- `entry_images`
- `deleted_records`
- `sync_queue`
- `app_settings`

Implementation approach:
- Add database opening and migration code.
- Add transaction helpers for multi-step writes.
- Add repository interfaces before UI forms depend on data.

## Phase 3 - Trader Management

Objective: manage trader accounts fully offline.

Features covered:
- Add trader.
- Edit trader.
- Soft delete trader.
- Restore trader.
- Trader profile.
- Trader search by name/mobile.

Packages:
- Uses Phase 2 database packages.

Architecture decisions:
- Trader feature owns UI and Riverpod providers.
- Database layer owns raw SQLite queries.
- Repository maps database rows to domain models.

Database planning:
- `traders` table with name, mobile, timestamps, deleted flag, sync state.
- Index trader name and mobile.

Implementation approach:
- Build forms optimized for fast entry.
- Validate required fields locally.
- Never require internet for trader work.

## Phase 4 - Entry Management

Objective: manage bills, cash, cheques, pending dues, and statuses offline.

Features covered:
- Create entry.
- Edit entry.
- Soft delete entry.
- Undo delete.
- Entry history.
- Pending amount calculation.
- Payment status calculation.

Packages:
- Uses Phase 2 database packages.

Architecture decisions:
- Entry calculation logic lives outside widgets.
- UI reads Riverpod state from repositories.

Database planning:
- `entries` table linked to `traders`.
- Fields: date, bill number, bill amount, cash amount, cheque amount, cheque
  number, deposit date, pending amount, status, notes, timestamps, sync state.
- Index bill number, date, cheque number, trader id, status.

Implementation approach:
- Save entry in a SQLite transaction.
- Calculate pending/status before persistence.
- Keep forms fast for daily business usage.

## Phase 5 - Image Management

Objective: store payment proofs and documents safely offline.

Features covered:
- Camera capture.
- Gallery upload.
- Max 15 images per entry.
- Preview images.
- Delete and undo image deletion.

Packages:
- `image_picker`
- `path_provider`

Architecture decisions:
- Store image files locally.
- Store image metadata and local path in SQLite.
- Upload/sync later through queue.

Database planning:
- `entry_images` table linked to `entries`.
- Fields: local path, remote path, deleted flag, sync state, timestamps.

Implementation approach:
- Copy picked images into app-controlled storage.
- Persist metadata transactionally.
- Enforce max image count locally.

## Phase 6 - Search And Dashboard

Objective: provide fast offline discovery and calculations.

Features covered:
- Search by bill number, trader name, amount, date, cheque number.
- Dashboard totals.
- Today, weekly, monthly collections.
- Pending amount.
- Upcoming deposits.
- Trader-wise totals.

Packages:
- `speech_to_text` for voice search.

Architecture decisions:
- Search queries run against indexed SQLite data.
- Dashboard providers expose calculated summaries.

Database planning:
- Add indexes as needed from real query patterns.
- Consider SQLite FTS later if text search grows.

Implementation approach:
- Start with efficient SQL queries.
- Avoid loading all records into memory.

## Phase 7 - Reports, Export, And Sharing

Objective: generate business reports from offline data.

Features covered:
- Trader-wise report.
- Overall report.
- Monthly detailed report.
- Date range filters.
- PDF export.
- Excel export.
- WhatsApp/file sharing.

Packages:
- `pdf`
- `excel`
- `share_plus`

Architecture decisions:
- Report generation is a service, not widget logic.
- Export files are generated from local database snapshots.

Database planning:
- Use indexed date/trader/status queries.

Implementation approach:
- Build report query models.
- Generate PDF/Excel files locally.
- Share generated files through platform share sheet.

## Phase 8 - Authentication And PIN Security

Objective: protect business data and owner access.

Features covered:
- Gmail login.
- Session persistence.
- Logout.
- PIN lock.

Packages:
- `firebase_auth`
- `google_sign_in`
- `flutter_secure_storage`

Architecture decisions:
- Auth controls access to the app.
- Local data remains available after successful local unlock.
- Client-owned Firebase project is required.
- Security scope is PIN-only.

Database planning:
- Store non-sensitive app auth flags in SQLite.
- Store PIN/session secrets in secure storage only.

Implementation approach:
- Add Firebase after client ownership is decided.
- Keep PIN support independent of network.

## Phase 9 - Reminders And Notifications

Objective: remind users about deposits and pending dues.

Features covered:
- Cheque deposit reminders.
- Pending payment reminders.
- Due reminders.
- Local notifications.
- Future push notifications if the client requests them.

Packages:
- `flutter_local_notifications`
- Firebase Messaging is deferred.

Architecture decisions:
- Local reminders are scheduled from local database records.
- Push notifications are optional future support.

Database planning:
- Add reminder settings and notification scheduling metadata.

Implementation approach:
- Schedule notifications when entries are created/updated.
- Rebuild schedules from local data after restore.

## Phase 10 - Backup, Restore, And Scale

Objective: protect data and keep recovery reliable.

Features covered:
- Local backup.
- Cloud backup.
- Google Drive backup.
- Restore.
- Conflict metadata.

Packages:
- `firebase_storage` for backup files.
- Firebase core packages.
- Google Drive API packages for app-data backup.
- `archive` for compressed backup zip files.

Architecture decisions:
- SQLite remains primary source of truth.
- Sync is silent, queued, and retryable.
- Client owns Firebase and backup accounts.

Database planning:
- `sync_queue` tracks pending creates/updates/deletes.
- Each syncable table has sync state and remote id fields.

Implementation approach:
- Build local backup and restore first.
- Compress database snapshots, settings, and proof files into `backup.zip`.
- Add cloud backup through Firebase Storage.
- Use transactions and idempotent operations.
- Never block data entry on cloud availability.
