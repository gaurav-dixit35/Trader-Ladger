import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../application/pin_lock_providers.dart';
import '../../domain/pin_lock_state.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinLockControllerProvider);
    final isSetup = pinState.status == PinLockStatus.setupRequired;

    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle(title: AppConstants.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.spacingXxl),
          children: [
            Image.asset(
              'others/logo.png',
              width: 96,
              height: 96,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.lock_outline,
                  size: AppLayout.iconXl,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            const SizedBox(height: AppLayout.spacingLg),
            Text(
              isSetup ? 'Set app PIN' : 'Enter app PIN',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppLayout.spacingSm),
            Text(
              isSetup
                  ? 'Create a 4 to 6 digit PIN for offline access.'
                  : 'Unlock Trader Ledger App to continue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppLayout.spacingXxl),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
              onSubmitted: (_) => _submit(isSetup),
            ),
            if (isSetup) ...[
              const SizedBox(height: AppLayout.spacingMd),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                onSubmitted: (_) => _submit(isSetup),
              ),
            ],
            if (pinState.errorMessage != null) ...[
              const SizedBox(height: AppLayout.spacingSm),
              Text(
                pinState.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppLayout.spacingLg),
            FilledButton.icon(
              onPressed: _isSaving ? null : () => _submit(isSetup),
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_open_outlined),
              label: Text(isSetup ? 'Save PIN' : 'Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(bool isSetup) async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (isSetup) {
        await ref.read(pinLockControllerProvider.notifier).setPin(
              pin: _pinController.text.trim(),
              confirmPin: _confirmPinController.text.trim(),
            );
      } else {
        await ref
            .read(pinLockControllerProvider.notifier)
            .unlock(_pinController.text.trim());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
