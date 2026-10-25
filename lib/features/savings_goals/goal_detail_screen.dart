import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../accounts/accounts_provider.dart';
import 'savings_goals_provider.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider).valueOrNull ?? [];
    SavingsGoal? goal;
    for (final g in goals) {
      if (g.id == goalId) goal = g;
    }

    if (goal == null) {
      return const Scaffold(
        body: Center(child: Text('Objectif introuvable ou supprimé.')),
      );
    }

    final percent = (goal.progressRatio * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expense),
            onPressed: () => _confirmDelete(context, ref, goal!),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: goal.progressRatio,
                      strokeWidth: 14,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _infoCard('Épargné', goal.savedAmount, AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                    'Restant', goal.remainingAmount, AppColors.textSecondary),
              ),
            ],
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 20),
            const Text('Plan d\'épargne',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (goal.suggestedDailyAmount != null)
                    Text(
                      '${goal.suggestedDailyAmount!.toStringAsFixed(0)} FCFA / jour',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  if (goal.suggestedMonthlyAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${goal.suggestedMonthlyAmount!.toStringAsFixed(0)} FCFA / mois',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Pour atteindre l\'objectif au ${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}'
                    '${goal.daysRemaining != null ? ' (${goal.daysRemaining} jours restants)' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => _showAddMoneyDialog(context, ref, goal!),
            child: const Text('Ajouter de l\'argent'),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${amount.toStringAsFixed(0)} FCFA',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    final amountController = TextEditingController();
    Account? selectedAccount;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final accountsAsync = ref.watch(accountsProvider);

            return AlertDialog(
              title: const Text('Ajouter de l\'argent'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  accountsAsync.when(
                    data: (accounts) => DropdownButtonFormField<Account>(
                      initialValue: selectedAccount,
                      decoration:
                          const InputDecoration(labelText: 'Depuis quel compte ?'),
                      items: accounts
                          .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedAccount = value),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('Erreur : $e'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || selectedAccount == null) return;

                    final db = ref.read(databaseProvider);
                    await db.addMoneyToGoal(
                      goalId: goal.id,
                      amount: amount,
                      accountId: selectedAccount!.id,
                    );

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet objectif ?'),
        content: Text(
            'L\'argent déjà épargné (${goal.savedAmount.toStringAsFixed(0)} FCFA) ne sera pas remboursé sur tes comptes — seul l\'objectif sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteSavingsGoal(goal.id);
              if (context.mounted) {
                Navigator.pop(context); // ferme le dialog
                Navigator.pop(context); // revient à la liste
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}