# Trader Ledger App Local Database Schema

The local SQLite database is the primary source of truth for Trader Ledger App.

## Storage Rules

- Money is stored as integer rupees for now.
- Dates are stored as UTC milliseconds since epoch.
- Deletes are soft deletes by default.
- Sync is tracked separately from local writes.
- Cloud backup/sync must never block local data entry.

## Tables

### app_settings

Stores local app settings such as selected language, security flags, and future
backup preferences.

### traders

Stores trader accounts.

Important indexes:
- `name`
- `mobile_number`

### entries

Stores bill/payment entries.

Important indexes:
- `trader_id`
- `entry_date`
- `bill_number`
- `cheque_number`
- `payment_status`

### entry_images

Stores local proof image metadata linked to entries. Actual image files will be
stored in app-controlled storage in the image management phase.

### deleted_records

Stores deletion snapshots for undo and recycle-bin restoration.

### sync_queue

Stores pending cloud sync operations. This queue will be processed only when
internet is available.
