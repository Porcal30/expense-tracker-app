import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/category.dart';
import '../providers/expense_provider.dart';

class ExpenseFilterSheet extends StatefulWidget {
  final ExpenseProvider expenseProvider;
  final List<Category> categories;

  const ExpenseFilterSheet({
    super.key,
    required this.expenseProvider,
    required this.categories,
  });

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  String? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'date_desc';

  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.expenseProvider.selectedCategoryId;
    _startDate = widget.expenseProvider.startDate;
    _endDate = widget.expenseProvider.endDate;
    _sortBy = widget.expenseProvider.sortBy;
    _minAmountController = TextEditingController(
      text: widget.expenseProvider.minAmount?.toString() ?? '',
    );
    _maxAmountController = TextEditingController(
      text: widget.expenseProvider.maxAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  bool get _isAmountRangeValid {
    final min = _parseAmount(_minAmountController.text);
    final max = _parseAmount(_maxAmountController.text);
    return min == null || max == null || min <= max;
  }

  double? _parseAmount(String value) {
    final normalized = value.trim().replaceAll(',', '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String get _dateRangeLabel {
    if (_startDate == null && _endDate == null) {
      return 'Any date';
    }

    final formatter = DateFormat('MMM d, yyyy');
    if (_startDate != null && _endDate != null) {
      return '${formatter.format(_startDate!)} – ${formatter.format(_endDate!)}';
    }

    if (_startDate != null) {
      return 'From ${formatter.format(_startDate!)}';
    }

    return 'Until ${formatter.format(_endDate!)}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _startDate ?? now.subtract(const Duration(days: 30));
    final initialEnd = _endDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _applyFilters() {
    widget.expenseProvider.setSelectedCategoryId(_selectedCategoryId);
    widget.expenseProvider.setDateRange(_startDate, _endDate);
    widget.expenseProvider.setAmountRange(
      _parseAmount(_minAmountController.text),
      _parseAmount(_maxAmountController.text),
    );
    widget.expenseProvider.setSortBy(_sortBy);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = null;
      _startDate = null;
      _endDate = null;
      _sortBy = 'date_desc';
      _minAmountController.clear();
      _maxAmountController.clear();
    });

    widget.expenseProvider.resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Expense filters',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Refine your results by category, date, amount, or sort order.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...widget.categories.map(
                    (category) => DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDateRange,
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Date range',
                      hintText: 'Select date range',
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      helperText: _dateRangeLabel,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Min amount',
                        prefixText: '₱',
                        hintText: '0.00',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Max amount',
                        prefixText: '₱',
                        hintText: '0.00',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isAmountRangeValid) ...[
                const SizedBox(height: 8),
                Text(
                  'Minimum amount must be less than or equal to maximum amount.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sort by',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'date_desc',
                    child: Text('Date: newest first'),
                  ),
                  DropdownMenuItem(
                    value: 'date_asc',
                    child: Text('Date: oldest first'),
                  ),
                  DropdownMenuItem(
                    value: 'amount_desc',
                    child: Text('Amount: high to low'),
                  ),
                  DropdownMenuItem(
                    value: 'amount_asc',
                    child: Text('Amount: low to high'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _sortBy = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isAmountRangeValid ? _applyFilters : null,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
