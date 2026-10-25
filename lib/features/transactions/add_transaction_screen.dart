import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.existingTransaction});

  final Transaction? existingTransaction;

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Account? _selectedAccount;
  Account? _toAccount;
  Category? _selectedCategory;
  String _type = 'expense';
  bool _initialized = false;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    if (!_initialized && widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      final categories = categoriesAsync.value ?? [];
      final accounts = accountsAsync.value ?? [];
      _labelController.text = tx.label;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.date;
      for (final c in categories) {
        if (c.id == tx.categoryId) _selectedCategory = c;
      }
      _type = _selectedCategory?.type ?? 'expense';
      for (final a in accounts) {
        if (a.id == tx.accountId) _selectedAccount = a;
      }
      if (categories.isNotEmpty && accounts.isNotEmpty) _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifier la transaction' : 'Nouvelle transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (!_isEditing) ...[
              _buildTypeToggle(),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_type != 'transfer') ...[
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Libellé (ex : Taxi, Marché...)'),
              ),
              const SizedBox(height: 12),
            ],
            accountsAsync.when(
              data: (accounts) => DropdownButtonFormField<Account>(
                initialValue: _selectedAccount,
                decoration: InputDecoration(
                    labelText: _type == 'transfer' ? 'Depuis quel compte' : 'Compte'),
                items: accounts
                    .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedAccount = value),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur : $e'),
            ),
            const SizedBox(height: 12),
            if (_type == 'transfer')
              accountsAsync.when(
                data: (accounts) => DropdownButtonFormField<Account>(
                  initialValue: _toAccount,
                  decoration: const InputDecoration(labelText: 'Vers quel compte'),
                  items: accounts
                      .where((a) => a.id != _selectedAccount?.id)
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _toAccount = value),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Erreur : $e'),
              ),
            if (_type != 'transfer')
              categoriesAsync.when(
                data: (categories) {
                  final filtered = categories.where((c) => c.type == _type).toList();
                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: filtered
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Erreur : $e'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (facultatif)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date : ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'Enregistrer les modifications' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    Widget chip(String value, String label) {
      final selected = _type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _type = value;
            _selectedCategory = null;
            _toAccount = null;
          }),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [chip('expense', 'Dépense'), chip('income', 'Revenu'), chip('transfer', 'Transfert')]);
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
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remplis tous les champs.')));
      return;
    }

    final db = ref.read(databaseProvider);
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    if (_type == 'transfer') {
      if (_toAccount == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Choisis le compte de destination.')));
        return;
      }
      await db.addTransfer(
        amount: amount,
        date: _selectedDate,
        fromAccountId: _selectedAccount!.id,
        toAccountId: _toAccount!.id,
        note: note,
      );
    } else {
      final label = _labelController.text.trim();
      if (label.isEmpty || _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remplis tous les champs.')));
        return;
      }

      if (_isEditing) {
        await db.updateTransaction(
          id: widget.existingTransaction!.id,
          label: label,
          amount: amount,
          date: _selectedDate,
          accountId: _selectedAccount!.id,
          categoryId: _selectedCategory!.id,
          isExpense: _type == 'expense',
          note: note,
        );
      } else {
        await db.addTransaction(
          label: label,
          amount: amount,
          date: _selectedDate,
          accountId: _selectedAccount!.id,
          categoryId: _selectedCategory!.id,
          isExpense: _type == 'expense',
          note: note,
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }
}