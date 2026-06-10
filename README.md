# Trader Ledger App

Trader Ledger App is an offline-first Flutter app for managing trader bills, payments, deposits, reminders, reports, backups, and user-scoped cloud sync.

## Features

- Multiuser authentication with email/password and Google sign-in.
- Per-user local SQLite database so records stay separate on shared devices.
- Per-user Firestore sync under `users/{uid}`.
- Google Drive backup and restore for the signed-in user account.
- Trader management, bill entries, payment status, deposit tracking, and proof images.
- Dashboard totals for cash, cheque, pending amounts, and upcoming deposits.
- PDF/Excel reports, sharing, printing, recycle bin recovery, PIN lock, and reminders.

## Tech Stack

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Google Drive API
- SQLite via `sqflite`
- Riverpod, GoRouter, Material 3

## Setup

1. Install Flutter and platform tooling.
2. Create your own Firebase project.
3. Enable Firebase Authentication providers:
   - Email/password
   - Google
4. Enable Cloud Firestore.
5. Enable the Google Drive API in the same Google Cloud project if you want Drive backup.
6. Generate Firebase config files for your project:
   - `lib/config/firebase_options.dart`
   - `android/app/google-services.json`
   - iOS/macOS config files if you target Apple platforms
7. Deploy `firebase/firestore.rules` to your Firebase project.
8. Run the app with your normal Flutter workflow.

## Firestore Rules

The included rules isolate every user's synced records:

```text
users/{uid}/...
```

Only the authenticated user whose UID matches the document path can read or write those records.

## Google Drive Backup

Drive backup uses the Google account currently authenticated in the app. The app checks the Drive account email before upload/restore so one user's backup is not written to another user's Drive.

## Open Source Safety

This repository should not contain personal Firebase keys, Google client IDs, local SDK paths, keystores, signing files, generated build output, logs, or private client documentation.

Before pushing to GitHub, create your own Firebase configuration locally and keep it uncommitted. The `.gitignore` is configured to exclude common private/generated files.

## Notes

- The app is offline-first. Local data entry works without internet.
- Cloud sync and Drive backup require a configured Firebase/Google Cloud project.
- Existing deployments should migrate users carefully because the upgraded app stores data per authenticated UID.
