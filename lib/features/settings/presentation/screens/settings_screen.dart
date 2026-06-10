import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_router.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../notifications/application/notification_providers.dart';
import '../../../security/application/pin_lock_providers.dart';
import '../../../sync/application/cloud_sync_providers.dart';
import '../../application/backup_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupControllerProvider);
    final syncState = ref.watch(cloudSyncControllerProvider);
    final userEmail =
        ref.watch(authStateProvider).asData?.value?.email ?? 'Signed in user';
    final isBackupRunning = backupState.isLoading;
    final isSyncRunning = syncState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle(title: 'Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.spacingLg),
        children: [
          _SectionLabel('Security'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change app PIN'),
              subtitle: const Text('Update the 4 to 6 digit app lock PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePinSheet(context),
            ),
          ),
          const SizedBox(height: AppLayout.spacingMd),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('Lock app now'),
              subtitle: const Text('Require PIN before continuing'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(pinLockControllerProvider.notifier).lockIfPinSet();
              },
            ),
          ),
          const SizedBox(height: AppLayout.spacingMd),
          _SectionLabel('Live sync'),
          Card(
            child: Column(
              children: [
                if (isSyncRunning) const LinearProgressIndicator(),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Sync records now'),
                  subtitle: const Text('Sync traders and entries using Firestore'),
                  enabled: !isSyncRunning,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: isSyncRunning ? null : () => _syncNow(context, ref),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.image_outlined),
                  title: Text('Images'),
                  subtitle: Text('Images are included in Google Drive backup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.spacingMd),
          _SectionLabel('Data recovery'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Recycle bin'),
              subtitle: const Text('Restore deleted traders and entries'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoute.recycleBin.path),
            ),
          ),
          const SizedBox(height: AppLayout.spacingMd),
          Card(
            child: Column(
              children: [
                if (isBackupRunning) const LinearProgressIndicator(),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Create local backup'),
                  subtitle: const Text('Save a full offline database snapshot'),
                  enabled: !isBackupRunning,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: isBackupRunning
                      ? null
                      : () => _createLocalBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_to_drive_outlined),
                  title: const Text('Upload Google Drive backup'),
                  subtitle: Text('Saves to Drive for $userEmail'),
                  enabled: !isBackupRunning,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: isBackupRunning
                      ? null
                      : () => _uploadDriveBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: const Text('Restore Google Drive backup'),
                  subtitle: const Text('Use the backup saved in Drive'),
                  enabled: !isBackupRunning,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: isBackupRunning
                      ? null
                      : () => _confirmDriveRestore(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.spacingMd),
          _SectionLabel('Preferences'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.language_outlined),
              title: Text('Language'),
              subtitle: Text('English'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: AppLayout.spacingMd),
          _SectionLabel('Reminders'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Refresh reminders'),
              subtitle: const Text('Cheque deposit and pending payment alerts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _refreshReminders(context, ref),
            ),
          ),
          const SizedBox(height: AppLayout.spacingMd),
          _SectionLabel('Account'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: Text(userEmail),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshReminders(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(reminderSchedulerProvider).refreshSchedules();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count reminders scheduled')),
    );
  }

  void _showChangePinSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ChangePinSheet(),
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(cloudSyncControllerProvider.notifier)
          .syncNow();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync complete: ${result.pushedRecords} uploaded, '
            '${result.pulledRecords} downloaded.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showServiceError(context, 'Sync failed', error);
    }
  }

  Future<void> _createLocalBackup(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(backupControllerProvider.notifier)
          .createLocalBackup();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup saved with ${result.recordCount} records.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showServiceError(context, 'Backup failed', error);
    }
  }

  Future<void> _uploadDriveBackup(BuildContext context, WidgetRef ref) async {
    try {
      final driveFileId = await ref
          .read(backupControllerProvider.notifier)
          .uploadGoogleDriveBackup();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Drive backup saved: $driveFileId')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showServiceError(context, 'Backup failed', error);
    }
  }

  Future<void> _confirmDriveRestore(BuildContext context, WidgetRef ref) async {
    final shouldRestore = await _confirmRestore(
      context: context,
      message:
          'This will replace local records with the latest Google Drive backup.',
    );

    if (shouldRestore != true || !context.mounted) {
      return;
    }

    await _restoreDriveBackup(context, ref);
  }

  Future<void> _restoreDriveBackup(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(backupControllerProvider.notifier)
          .restoreGoogleDriveBackup();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Drive backup restored.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showServiceError(context, 'Backup failed', error);
    }
  }

  Future<bool?> _confirmRestore({
    required BuildContext context,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_outlined),
          title: const Text('Restore backup?'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  void _showServiceError(BuildContext context, String title, Object error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title: ${_friendlyServiceError(error)}')),
    );
  }

  String _friendlyServiceError(Object error) {
    final message = error.toString();
    if (message.contains('insufficient') ||
        message.contains('permission') ||
        message.contains('403')) {
      return 'permission denied. Check Google Drive or Firestore settings.';
    }
    if (message.contains('network') || message.contains('SocketException')) {
      return 'network unavailable. Try again when internet works.';
    }

    return message;
  }
}

class _ChangePinSheet extends ConsumerStatefulWidget {
  const _ChangePinSheet();

  @override
  ConsumerState<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends ConsumerState<_ChangePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppLayout.spacingLg,
          right: AppLayout.spacingLg,
          top: AppLayout.spacingLg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppLayout.spacingLg,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Change app PIN',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppLayout.spacingLg),
              _PinField(
                controller: _currentPinController,
                label: 'Current PIN',
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: AppLayout.spacingMd),
              _PinField(
                controller: _newPinController,
                label: 'New PIN',
                icon: Icons.pin_outlined,
              ),
              const SizedBox(height: AppLayout.spacingMd),
              _PinField(
                controller: _confirmPinController,
                label: 'Confirm new PIN',
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: AppLayout.spacingLg),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final changed = await ref.read(pinLockControllerProvider.notifier).changePin(
          currentPin: _currentPinController.text.trim(),
          newPin: _newPinController.text.trim(),
          confirmPin: _confirmPinController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (!changed) {
      final error = ref.read(pinLockControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not change PIN')),
      );
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App PIN changed.')),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        final pin = value?.trim() ?? '';
        if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
          return 'PIN must be 4 to 6 digits.';
        }
        return null;
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppLayout.spacingSm,
        bottom: AppLayout.spacingSm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
