import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../data/models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  bool _isSaving = false;

  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final expense = widget.expense!;
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _noteController.text = expense.note ?? '';
      _selectedDate = expense.date;
      _selectedCategoryId = expense.categoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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
      final provider = context.read<ExpenseProvider>();

      if (_isEditMode) {
        // Edit mode: preserve original fields
        final original = widget.expense!;
        final updatedExpense = original.copyWith(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          updatedAt: DateTime.now(),
        );
        
        await provider.updateExpense(updatedExpense);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add mode: create new expense
        final expense = Expense(
          id: const Uuid().v4(),
          userId: auth.user!.uid,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId!,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await provider.addExpense(expense);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save expense. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final appBarTitle = _isEditMode ? 'Edit Expense' : 'Add Expense';
    final buttonText = _isEditMode ? 'Update Expense' : 'Save Expense';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
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
                  validator: (value) => Validators.requiredText(value, field: 'Title'),
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
                  initialValue: _selectedCategoryId,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: _isSaving ? null : (value) => setState(() => _selectedCategoryId = value),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      'Date: ${_selectedDate.toLocal().toString().split(' ').first}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: !_isSaving
                        ? IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                          )
                        : null,
                  ),
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
                  label: buttonText,
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

// Wrapper to navigate to AddEditExpenseScreen with optional expense argument
class AddEditExpenseRoute {
  static void navigateToAdd(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.addEditExpense);
  }

  static void navigateToEdit(BuildContext context, Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(expense: expense),
      ),
    );
  }
}
