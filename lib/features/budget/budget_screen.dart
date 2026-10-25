import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../categories/categories_provider.dart';
import 'budget_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Color _statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.onTrack:
        return AppColors.income;
      case BudgetStatus.watch:
        return AppColors.warning;
      case BudgetStatus.atRisk:
        return Colors.deepOrange;
      case BudgetStatus.exceeded:
        return AppColors.expense;
    }
  }

  String _statusLabel(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.onTrack:
        return 'Dans le budget';
      case BudgetStatus.watch:
        return 'À surveiller';
      case BudgetStatus.atRisk:
        return 'Risque de dépassement';
      case BudgetStatus.exceeded:
        return 'Budget dépassé';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(budgetSummaryProvider);
    final overview = ref.watch(budgetOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: summaries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: summaries.isEmpty ? 24 : 16),
              child: Column(
                children: [
                  _buildOverview(overview),
                  if (summaries.isEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Aucun budget défini par catégorie.\nAppuie sur + pour en fixer un.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            );
          }

          final s = summaries[index - 1];
          final status = s.status;
          final color = _statusColor(status);
          final realizedRatio = s.budgetLimit > 0 ? (s.realized / s.budgetLimit).clamp(0.0, 1.0) : 0.0;
          final engagedRatio =
              s.budgetLimit > 0 ? ((s.realized + s.planned) / s.budgetLimit).clamp(0.0, 1.0) : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      GestureDetector(
                        onTap: () => _showSetBudgetDialog(context, ref, s.category, s.budgetLimit),
                        child: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                    child: Text(_statusLabel(status),
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: engagedRatio,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(color.withAlpha(90)),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: realizedRatio,
                          minHeight: 10,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _infoBlock('Réalisé', s.realized)),
                    Expanded(child: _infoBlock('Déjà prévu', s.planned)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _infoBlock('Disponible réel', s.availableReal)),
                    Expanded(child: _infoBlock('Restant après planifié', s.remainingAfterPlanned)),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSetBudgetDialog(context, ref, null, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverview(BudgetOverview overview) {
    final percent = (overview.ratio * 100).round();
    final maxDaily =
        overview.dailySeries.isEmpty ? 1.0 : overview.dailySeries.reduce((a, b) => a > b ? a : b);
    final safeMax = maxDaily <= 0 ? 1.0 : maxDaily;
    final gaugeColor =
        percent >= 100 ? AppColors.expense : (percent >= 80 ? AppColors.warning : AppColors.primary);

    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Vue d'ensemble", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: overview.ratio,
                    strokeWidth: 14,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(gaugeColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$percent%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const Text('Utilisé', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _statBlock('Moyenne / jour', overview.dailyAverage)),
            Expanded(child: _statBlock('Dépenses totales', overview.totalRealized)),
          ]),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Évolution ce mois-ci', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: overview.dailySeries.map((value) {
                final height = 4 + (value / safeMax) * 36;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(value == 0 ? 40 : 200),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('${amount.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _infoBlock(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text('${amount.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  void _showSetBudgetDialog(BuildContext context, WidgetRef ref, Category? initialCategory, double? initialAmount) {
    final amountController =
        TextEditingController(text: initialAmount != null ? initialAmount.toStringAsFixed(0) : '');
    Category? selectedCategory = initialCategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final categoriesAsync = ref.watch(categoriesProvider);

            return AlertDialog(
              title: Text(initialCategory == null ? 'Définir un budget' : 'Modifier le budget'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  categoriesAsync.when(
                    data: (categories) {
                      final expenseCategories = categories.where((c) => c.type == 'expense').toList();
                      return DropdownButtonFormField<Category>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Catégorie'),
                        items: expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: initialCategory != null ? null : (value) => setState(() => selectedCategory = value),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('Erreur : $e'),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Budget mensuel (FCFA)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (selectedCategory == null || amount == null) return;
                    final db = ref.read(databaseProvider);
                    await db.setBudget(selectedCategory!.id, amount);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}