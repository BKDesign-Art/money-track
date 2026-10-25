import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../categories/categories_provider.dart';
import '../planned_expenses/plan_expense_screen.dart';
import '../alerts/alerts_provider.dart';
import '../profile/profile_provider.dart';
import '../profile/profile_screen.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _relativeDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Demain';
    const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${months[date.month - 1]}';
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return AppColors.expense;
      case 'high':
        return AppColors.warning;
      case 'low':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  Color _alertColor(AlertSeverity severity) => severity == AlertSeverity.danger ? AppColors.expense : AppColors.warning;
  Color _alertBackground(AlertSeverity severity) =>
      severity == AlertSeverity.danger ? AppColors.expenseLight : AppColors.warningLight;
  IconData _alertIcon(AlertSeverity severity) =>
      severity == AlertSeverity.danger ? Icons.error_outline : Icons.warning_amber_rounded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final weekTotal = ref.watch(plannedThisWeekTotalProvider);
    final monthTotal = ref.watch(plannedThisMonthTotalProvider);
    final upcoming = ref.watch(upcomingPlannedExpensesProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final alerts = ref.watch(timelineAlertsProvider);
    final dailyBudget = ref.watch(dailyBudgetProvider);
    final projection = ref.watch(monthProjectionProvider);

    Category? findCategory(int id) {
      for (final c in categories) {
        if (c.id == id) return c;
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour ${profile.name} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Pas de nouvelle notification.'))),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solde total', style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 13)),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('${totalBalance.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildDailyBudgetCard(dailyBudget),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _summaryCard('Prévues cette semaine', weekTotal)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Prévues ce mois', monthTotal)),
            ],
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...alerts.map((alert) {
              final color = _alertColor(alert.severity);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  color: _alertBackground(alert.severity),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_alertIcon(alert.severity), color: color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert.title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                            const SizedBox(height: 2),
                            Text(alert.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 14),
          _buildProjectionCard(projection),
          const SizedBox(height: 22),
          const Text('Prochaines dépenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aucune dépense planifiée pour le moment.')),
            )
          else
            ...upcoming.take(5).map((expense) {
              final category = findCategory(expense.categoryId);
              final color = _priorityColor(expense.priority);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
                        child: Icon(Icons.schedule, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expense.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(category?.name ?? '...', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_relativeDateLabel(expense.plannedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('${expense.amount.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlanExpenseScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Planifier'),
      ),
    );
  }

  Widget _buildDailyBudgetCard(DailyBudgetInfo daily) {
    final color = daily.isOverBudget ? AppColors.expense : AppColors.primary;
    final remainingToday = daily.dailyAllowance - daily.spentToday;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Budget quotidien', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Text("Aujourd'hui", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('${daily.dailyAllowance.clamp(0.0, double.infinity).toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: daily.ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            daily.isOverBudget
                ? 'Dépassé de ${(-remainingToday).toStringAsFixed(0)} FCFA aujourd\'hui'
                : 'Tu peux encore dépenser ${remainingToday.toStringAsFixed(0)} FCFA aujourd\'hui',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionCard(MonthProjection projection) {
    final isPositive = projection.projectedRemaining >= 0;
    final color = isPositive ? AppColors.income : AppColors.expense;
    final series = projection.cumulativeSeries;
    final maxValue = series.isEmpty ? 1.0 : series.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Projection fin de mois', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            isPositive
                ? 'Tu devrais finir le mois avec ${projection.projectedRemaining.toStringAsFixed(0)} FCFA restants'
                : 'Dépassement prévu de ${(-projection.projectedRemaining).toStringAsFixed(0)} FCFA',
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: series.isEmpty
                ? const SizedBox.shrink()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: series.map((value) {
                      final height = 4 + (value / safeMax) * 32;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(160),
                              borderRadius: BorderRadius.circular(2),
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

  Widget _summaryCard(String label, double amount) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('${amount.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}