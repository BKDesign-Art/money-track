import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../categories/categories_provider.dart';
import '../categories/category_style.dart';
import 'planned_expenses_provider.dart';

class PlannedExpensesTab extends ConsumerWidget {
  const PlannedExpensesTab({super.key});

  Category? _findCategory(List<Category> categories, int id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannedAsync = ref.watch(plannedExpensesProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];

    return plannedAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune dépense planifiée.\nAppuie sur + pour en ajouter une.', textAlign: TextAlign.center),
            ),
          );
        }
        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  final category = _findCategory(categories, expense.categoryId);
                  final style = category != null
                      ? categoryStyleFor(category)
                      : const CategoryStyle(icon: Icons.category, color: AppColors.textSecondary);
                  final date = expense.plannedDate;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      onTap: () => _showActions(context, ref, expense),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: style.color.withAlpha(30), shape: BoxShape.circle),
                            child: Icon(style.icon, color: style.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(expense.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${category?.name ?? '...'} • Dans ${date.difference(DateTime.now()).inDays} j',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text('-${expense.amount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SoftCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total à payer', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${total.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.expense)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur : $error')),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, PlannedExpense expense) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.income),
              title: const Text('Marquer comme effectuée'),
              onTap: () async {
                await ref.read(databaseProvider).convertPlannedExpenseToTransaction(expense.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.expense),
              title: const Text('Annuler'),
              onTap: () async {
                await ref.read(databaseProvider).cancelPlannedExpense(expense.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}