import 'package:flutter/material.dart';

import '../../../../core/constants/app_layout.dart';
import '../../domain/trader.dart';

class TraderForm extends StatefulWidget {
  const TraderForm({
    required this.onSubmit,
    this.initialTrader,
    super.key,
  });

  final Trader? initialTrader;
  final Future<void> Function({
    required String name,
    String? mobileNumber,
    String? notes,
  }) onSubmit;

  @override
  State<TraderForm> createState() => _TraderFormState();
}

class _TraderFormState extends State<TraderForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final trader = widget.initialTrader;
    _nameController = TextEditingController(text: trader?.name ?? '');
    _mobileController = TextEditingController(text: trader?.mobileNumber ?? '');
    _notesController = TextEditingController(text: trader?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTrader != null;

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
                isEditing ? 'Edit trader' : 'Add trader',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppLayout.spacingLg),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Trader name',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Trader name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppLayout.spacingMd),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixIcon: Icon(Icons.call_outlined),
                ),
              ),
              const SizedBox(height: AppLayout.spacingMd),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
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
                label: Text(isEditing ? 'Save Trader' : 'Add Trader'),
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

    try {
      await widget.onSubmit(
        name: _nameController.text,
        mobileNumber: _mobileController.text,
        notes: _notesController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
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
