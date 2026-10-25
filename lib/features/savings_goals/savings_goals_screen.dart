import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import 'savings_goals_provider.dart';
import 'goal_detail_screen.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes objectifs')),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucun objectif pour le moment.\nAppuie sur + pour en créer un.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final percent = (goal.progressRatio * 100).round();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalDetailScreen(goalId: goal.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                goal.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: goal.progressRatio,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Épargné : ${goal.savedAmount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              'Cible : ${goal.targetAmount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? targetDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nouvel objectif'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: "Nom (ex : Ordinateur portable)"),
                  ),
                  TextField(
                    controller: amountController,
                    decoration:
                        const InputDecoration(labelText: 'Montant cible (FCFA)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      targetDate == null
                          ? 'Date cible (optionnel)'
                          : '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}',
                    ),
                    trailing: targetDate == null
                        ? const Icon(Icons.calendar_today, size: 20)
                        : IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => targetDate = null),
                          ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => targetDate = picked);
                    },
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
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text);
                    if (name.isEmpty || amount == null) return;

                    final db = ref.read(databaseProvider);
                    await db.addSavingsGoal(
                      name: name,
                      targetAmount: amount,
                      targetDate: targetDate,
                    );

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}