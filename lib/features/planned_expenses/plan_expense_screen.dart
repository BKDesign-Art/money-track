import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';

class PlanExpenseScreen extends ConsumerStatefulWidget {
  const PlanExpenseScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<PlanExpenseScreen> createState() => _PlanExpenseScreenState();
}

class _PlanExpenseScreenState extends ConsumerState<PlanExpenseScreen> {
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  late DateTime _selectedDate =
      widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
  Account? _selectedAccount;
  Category? _selectedCategory;
  String _priority = 'medium';

  static const _priorities = {
    'low': 'Basse',
    'medium': 'Moyenne',
    'high': 'Haute',
    'critical': 'Critique',
  };

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Planifier une dépense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                  labelText: 'Libellé (ex : Loyer, Frais de scolarité...)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            accountsAsync.when(
              data: (accounts) => DropdownButtonFormField<Account>(
                initialValue: _selectedAccount,
                decoration: const InputDecoration(labelText: 'Compte prévu'),
                items: accounts
                    .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedAccount = value),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur : $e'),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) {
                final expenseCategories =
                    categories.where((c) => c.type == 'expense').toList();
                return DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: expenseCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur : $e'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priorité'),
              items: _priorities.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _priority = value ?? 'medium'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  'Date prévue : ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Planifier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final label = _labelController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (label.isEmpty ||
        amount == null ||
        _selectedAccount == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Remplis tous les champs.')));
      return;
    }

    final db = ref.read(databaseProvider);
    await db.addPlannedExpense(
      label: label,
      amount: amount,
      plannedDate: _selectedDate,
      accountId: _selectedAccount!.id,
      categoryId: _selectedCategory!.id,
      priority: _priority,
    );

    if (mounted) Navigator.pop(context);
  }
}