import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../traders/domain/trader.dart';
import '../../domain/business_entry.dart';

class EntryFormValues {
  const EntryFormValues({
    required this.traderId,
    required this.entryDate,
    required this.billNumber,
    required this.billAmount,
    required this.cashAmount,
    required this.chequeAmount,
    this.chequeNumber,
    this.depositDate,
    this.notes,
    this.imageSourcePaths = const [],
  });

  final String traderId;
  final DateTime entryDate;
  final String billNumber;
  final int billAmount;
  final int cashAmount;
  final int chequeAmount;
  final String? chequeNumber;
  final DateTime? depositDate;
  final String? notes;
  final List<String> imageSourcePaths;
}

class EntryForm extends StatefulWidget {
  const EntryForm({
    required this.traders,
    required this.onSubmit,
    this.initialEntry,
    this.onPickCamera,
    this.onPickGallery,
    super.key,
  });

  final List<Trader> traders;
  final BusinessEntry? initialEntry;
  final Future<void> Function(EntryFormValues values) onSubmit;
  final Future<String?> Function()? onPickCamera;
  final Future<String?> Function()? onPickGallery;

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _billNumberController;
  late final TextEditingController _billAmountController;
  late final TextEditingController _cashAmountController;
  late final TextEditingController _chequeAmountController;
  late final TextEditingController _chequeNumberController;
  late final TextEditingController _notesController;
  late String _traderId;
  late DateTime _entryDate;
  DateTime? _depositDate;
  final List<String> _imageSourcePaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _traderId = entry?.traderId ?? widget.traders.first.id;
    _entryDate = entry?.entryDate ?? DateTime.now();
    _depositDate = entry?.depositDate;
    _billNumberController = TextEditingController(
      text: entry?.billNumber ?? '',
    );
    _billAmountController = TextEditingController(
      text: entry?.billAmount.toString() ?? '',
    );
    _cashAmountController = TextEditingController(
      text: entry?.cashAmount.toString() ?? '0',
    );
    _chequeAmountController = TextEditingController(
      text: entry?.chequeAmount.toString() ?? '0',
    );
    _chequeNumberController = TextEditingController(
      text: entry?.chequeNumber ?? '',
    );
    _notesController = TextEditingController(text: entry?.notes ?? '');
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _billAmountController.dispose();
    _cashAmountController.dispose();
    _chequeAmountController.dispose();
    _chequeNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEntry != null;

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
                isEditing ? 'Edit entry' : 'New entry',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppLayout.spacingLg),
              DropdownButtonFormField<String>(
                initialValue: _traderId,
                decoration: const InputDecoration(
                  labelText: 'Trader',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: [
                  for (final trader in widget.traders)
                    DropdownMenuItem(
                      value: trader.id,
                      child: Text(trader.name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _traderId = value;
                    });
                  }
                },
              ),
              const SizedBox(height: AppLayout.spacingMd),
              _DateButton(
                icon: Icons.event_outlined,
                label: 'Entry date',
                value: DateFormatter.displayDate(_entryDate),
                onPressed: () => _pickEntryDate(context),
              ),
              const SizedBox(height: AppLayout.spacingMd),
              TextFormField(
                controller: _billNumberController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Bill number',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppLayout.spacingMd),
              TextFormField(
                controller: _billAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Bill amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                onTap: () => _selectZeroAmount(_billAmountController),
                validator: _requiredAmountValidator,
              ),
              const SizedBox(height: AppLayout.spacingMd),
              TextFormField(
                controller: _cashAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cash amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                onTap: () => _selectZeroAmount(_cashAmountController),
                validator: _optionalAmountValidator,
              ),
              const SizedBox(height: AppLayout.spacingMd),
              TextFormField(
                controller: _chequeAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cheque amount',
                  prefixIcon: Icon(Icons.fact_check_outlined),
                ),
                onTap: () => _selectZeroAmount(_chequeAmountController),
                validator: _optionalAmountValidator,
              ),
              const SizedBox(height: AppLayout.spacingMd),
              TextFormField(
                controller: _chequeNumberController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cheque number',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: AppLayout.spacingMd),
              _DateButton(
                icon: Icons.event_available_outlined,
                label: 'Deposit date',
                value: _depositDate == null
                    ? 'Not selected'
                    : DateFormatter.displayDate(_depositDate!),
                onPressed: () => _pickDepositDate(context),
                onClear: _depositDate == null
                    ? null
                    : () {
                        setState(() {
                          _depositDate = null;
                        });
                      },
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
              const SizedBox(height: AppLayout.spacingMd),
              _ProofPicker(
                count: _imageSourcePaths.length,
                onCamera: widget.onPickCamera == null
                    ? null
                    : () => _pickProofImage(widget.onPickCamera!),
                onGallery: widget.onPickGallery == null
                    ? null
                    : () => _pickProofImage(widget.onPickGallery!),
                onClear: _imageSourcePaths.isEmpty
                    ? null
                    : () {
                        setState(_imageSourcePaths.clear);
                      },
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
                label: Text(isEditing ? 'Save Entry' : 'Create Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickEntryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _entryDate,
    );
    if (picked != null) {
      setState(() {
        _entryDate = picked;
      });
    }
  }

  Future<void> _pickDepositDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _depositDate ?? _entryDate,
    );
    if (picked != null) {
      setState(() {
        _depositDate = picked;
      });
    }
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
        EntryFormValues(
          traderId: _traderId,
          entryDate: _entryDate,
          billNumber: _billNumberController.text,
          billAmount: _parseAmount(_billAmountController.text),
          cashAmount: _parseOptionalAmount(_cashAmountController.text),
          chequeAmount: _parseOptionalAmount(_chequeAmountController.text),
          chequeNumber: _chequeNumberController.text,
          depositDate: _depositDate,
          notes: _notesController.text,
          imageSourcePaths: List.unmodifiable(_imageSourcePaths),
        ),
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _requiredAmountValidator(String? value) {
    final amount = _parseAmount(value ?? '');
    if (amount < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  String? _optionalAmountValidator(String? value) {
    final amount = _parseOptionalAmount(value ?? '');
    if (amount < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  int _parseAmount(String value) {
    return int.tryParse(value.replaceAll(',', '').trim()) ?? -1;
  }

  int _parseOptionalAmount(String value) {
    final trimmed = value.replaceAll(',', '').trim();
    if (trimmed.isEmpty) {
      return 0;
    }

    return int.tryParse(trimmed) ?? -1;
  }

  void _selectZeroAmount(TextEditingController controller) {
    if (controller.text.trim() != '0') {
      return;
    }

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  Future<void> _pickProofImage(Future<String?> Function() picker) async {
    if (_imageSourcePaths.length >= AppConstants.maxEntryImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum ${AppConstants.maxEntryImages} proof images allowed.',
          ),
        ),
      );
      return;
    }

    final sourcePath = await picker();
    if (sourcePath == null) {
      return;
    }

    setState(() {
      _imageSourcePaths.add(sourcePath);
    });
  }
}

class _ProofPicker extends StatelessWidget {
  const _ProofPicker({
    required this.count,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  final int count;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.spacingMd),
        child: Row(
          children: [
            const Icon(Icons.image_outlined),
            const SizedBox(width: AppLayout.spacingMd),
            Expanded(child: Text('$count proof images selected')),
            IconButton(
              tooltip: 'Camera',
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
            IconButton(
              tooltip: 'Gallery',
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
            ),
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: AppLayout.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Clear date',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}
