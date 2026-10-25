import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import 'transactions_provider.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filter = 'all';
  bool _searching = false;
  final _searchController = TextEditingController();

  Account? _findAccount(List<Account> accounts, int id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? _findCategory(List<Category> categories, int id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Rechercher...', border: InputBorder.none),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchController.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _filterChip('all', 'Toutes'),
              _filterChip('expense', 'Dépenses'),
              _filterChip('income', 'Revenus'),
              _filterChip('transfer', 'Transferts'),
            ]),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = transactions.where((tx) {
                  final category = _findCategory(categories, tx.categoryId);
                  final matchesFilter = _filter == 'all' || category?.type == _filter;
                  final matchesSearch = query.isEmpty || tx.label.toLowerCase().contains(query);
                  return matchesFilter && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Aucune transaction pour le moment.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    final accountName = _findAccount(accounts, tx.accountId)?.name ?? '...';
                    final category = _findCategory(categories, tx.categoryId);
                    final type = category?.type ?? 'expense';
                    final isExpense = type == 'expense';
                    final isTransfer = type == 'transfer';
                    final color = isTransfer ? Colors.blue : (isExpense ? AppColors.expense : AppColors.income);
                    final icon =
                        isTransfer ? Icons.swap_horiz : (isExpense ? Icons.arrow_downward : Icons.arrow_upward);
                    final sign = isTransfer
                        ? (tx.label.startsWith('Transfert vers') ? '-' : '+')
                        : (isExpense ? '-' : '+');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TransactionDetailScreen(transactionId: tx.id)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${category?.name ?? '...'} • $accountName',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text('$sign${tx.amount.toStringAsFixed(0)} FCFA',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur : $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTransactionScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}