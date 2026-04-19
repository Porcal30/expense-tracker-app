import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/currency_utils.dart';
import '../../core/utils/validators.dart';
import '../../data/models/recurring_expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/recurring_expense_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class AddEditRecurringExpenseScreen extends StatefulWidget {
  final RecurringExpense? template;

  const AddEditRecurringExpenseScreen({super.key, this.template});

  @override
  State<AddEditRecurringExpenseScreen> createState() =>
      _AddEditRecurringExpenseScreenState();
}

class _AddEditRecurringExpenseScreenState extends State<AddEditRecurringExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _startDate;
  late String _frequency;
  late bool _isActive;
  String? _selectedCategoryId;
  bool _isSaving = false;

  bool get _isEditMode => widget.template != null;

  static const Set<String> _allowedFrequencies = {'daily', 'weekly', 'monthly'};

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note ?? '';
      _startDate = t.startDate;
      _frequency =
          _allowedFrequencies.contains(t.frequency) ? t.frequency : 'monthly';
      _isActive = t.isActive;
      _selectedCategoryId = t.categoryId;
    } else {
      _startDate = DateTime.now();
      _frequency = 'monthly';
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    if (_isSaving) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      final provider = context.read<RecurringExpenseProvider>();
      final uid = auth.user!.uid;
      final now = DateTime.now();

      if (_isEditMode) {
        final original = widget.template!;
        final updated = original.copyWith(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          frequency: _frequency,
          startDate: _startDate,
          isActive: _isActive,
          updatedAt: now,
        );
        await provider.updateRecurringExpense(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring expense updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final item = RecurringExpense(
          id: const Uuid().v4(),
          userId: uid,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          frequency: _frequency,
          startDate: _startDate,
          lastGeneratedDate: null,
          isActive: _isActive,
          createdAt: now,
          updatedAt: now,
        );
        await provider.addRecurringExpense(item);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring expense saved'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _frequencyLabel(String code) {
    switch (code) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final title = _isEditMode ? 'Edit recurring expense' : 'Add recurring expense';
    final dateStr = DateFormat.yMMMd().format(_startDate);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _titleController,
                  label: 'Title',
                  enabled: !_isSaving,
                  validator: (v) => Validators.requiredText(v, field: 'Title'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _amountController,
                  label: 'Amount',
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  validator: Validators.amount,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey<String?>(_selectedCategoryId),
                  initialValue: _selectedCategoryId,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _selectedCategoryId = value),
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Category is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(_frequency),
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _frequency = v);
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  'Preview: ${CurrencyUtils.format(double.tryParse(_amountController.text) ?? 0)} '
                  '(${_frequencyLabel(_frequency)})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: Text('Start date: $dateStr'),
                    subtitle: const Text('Expenses generate from this date onward'),
                    trailing: _isSaving
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickStartDate,
                          ),
                    onTap: _isSaving ? null : _pickStartDate,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Inactive templates never generate expenses'),
                  value: _isActive,
                  onChanged: _isSaving ? null : (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _noteController,
                  label: 'Note (optional)',
                  enabled: !_isSaving,
                  maxLines: 3,
                ),
                const SizedBox(height: 28),
                LoadingButton(
                  label: _isEditMode ? 'Save changes' : 'Save',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
