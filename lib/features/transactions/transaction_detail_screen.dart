import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import 'transactions_provider.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];
    final accounts = ref.watch(accountsProvider).value ?? [];

    Transaction? tx;
    for (final t in transactions) {
      if (t.id == transactionId) tx = t;
    }

    if (tx == null) {
      return const Scaffold(body: Center(child: Text('Transaction introuvable ou supprimée.')));
    }

    Category? category;
    for (final c in categories) {
      if (c.id == tx.categoryId) category = c;
    }
    Account? account;
    for (final a in accounts) {
      if (a.id == tx.accountId) account = a;
    }

    final type = category?.type ?? 'expense';
    final isExpense = type == 'expense';
    final isTransfer = type == 'transfer';
    final color = isTransfer ? Colors.blue : (isExpense ? AppColors.expense : AppColors.income);
    final icon = isTransfer ? Icons.swap_horiz : (isExpense ? Icons.arrow_downward : Icons.arrow_upward);
    final sign = isTransfer ? (tx.label.startsWith('Transfert vers') ? '-' : '+') : (isExpense ? '-' : '+');

    return Scaffold(
      appBar: AppBar(title: const Text('Détail')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(category?.name ?? tx.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('$sign${tx.amount.toStringAsFixed(0)} FCFA',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SoftCard(
            child: Column(
              children: [
                _row('Compte', account?.name ?? '...'),
                const Divider(height: 20),
                _row('Date',
                    '${tx.date.day}/${tx.date.month}/${tx.date.year} à ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}'),
                const Divider(height: 20),
                _row('Catégorie', category?.name ?? '...'),
                const Divider(height: 20),
                _row('Note', (tx.note == null || tx.note!.isEmpty) ? 'Aucune' : tx.note!),
                const Divider(height: 20),
                _row('Type', isTransfer ? 'Transfert' : (isExpense ? 'Dépense' : 'Revenu')),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              if (!isTransfer)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddTransactionScreen(existingTransaction: tx)),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                ),
              if (!isTransfer) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
                  onPressed: () => _confirmDelete(context, ref, tx!.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette transaction ?'),
        content: const Text('Le solde du compte concerné sera automatiquement rétabli.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteTransaction(id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}