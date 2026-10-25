import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../accounts/accounts_provider.dart';
import '../planned_expenses/planned_expenses_provider.dart';
import '../budget/budget_provider.dart';

final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? [];
  return accounts.fold<double>(0, (sum, a) => sum + a.balance);
});

final upcomingPlannedExpensesProvider = Provider<List<PlannedExpense>>((ref) {
  final planned = ref.watch(plannedExpensesProvider).value ?? [];
  final sorted = [...planned]..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
  return sorted;
});

final plannedThisWeekTotalProvider = Provider<double>((ref) {
  final planned = ref.watch(plannedExpensesProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekFromNow = today.add(const Duration(days: 7));
  return planned
      .where((pe) => !pe.plannedDate.isBefore(today) && pe.plannedDate.isBefore(weekFromNow))
      .fold<double>(0, (sum, pe) => sum + pe.amount);
});

final plannedThisMonthTotalProvider = Provider<double>((ref) {
  final planned = ref.watch(plannedExpensesProvider).value ?? [];
  final now = DateTime.now();
  return planned
      .where((pe) => pe.plannedDate.year == now.year && pe.plannedDate.month == now.month)
      .fold<double>(0, (sum, pe) => sum + pe.amount);
});

// ---------- BUDGET QUOTIDIEN ----------

class DailyBudgetInfo {
  final double dailyAllowance;
  final double spentToday;
  DailyBudgetInfo({required this.dailyAllowance, required this.spentToday});

  double get ratio =>
      dailyAllowance > 0 ? (spentToday / dailyAllowance).clamp(0.0, 1.0) : (spentToday > 0 ? 1.0 : 0.0);
  bool get isOverBudget => spentToday > dailyAllowance && dailyAllowance > 0;
}

final dailyBudgetProvider = Provider<DailyBudgetInfo>((ref) {
  final overview = ref.watch(budgetOverviewProvider);
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = (daysInMonth - now.day + 1).clamp(1, daysInMonth);
  final remainingBudget = overview.totalBudget - overview.totalRealized;
  final dailyAllowance = remainingBudget / daysRemaining;
  final spentToday = (overview.dailySeries.isNotEmpty && now.day - 1 < overview.dailySeries.length)
      ? overview.dailySeries[now.day - 1]
      : 0.0;
  return DailyBudgetInfo(dailyAllowance: dailyAllowance, spentToday: spentToday);
});

// ---------- PROJECTION FIN DE MOIS ----------

class MonthProjection {
  final double projectedTotal;
  final double projectedRemaining;
  final List<double> cumulativeSeries;
  MonthProjection({
    required this.projectedTotal,
    required this.projectedRemaining,
    required this.cumulativeSeries,
  });
}

final monthProjectionProvider = Provider<MonthProjection>((ref) {
  final overview = ref.watch(budgetOverviewProvider);
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysElapsed = now.day;

  final cumulative = <double>[];
  double running = 0;
  for (final v in overview.dailySeries) {
    running += v;
    cumulative.add(running);
  }

  final dailyPace = daysElapsed > 0 ? overview.totalRealized / daysElapsed : 0.0;
  final projectedTotal = dailyPace * daysInMonth;
  final projectedRemaining = overview.totalBudget - projectedTotal;

  return MonthProjection(
    projectedTotal: projectedTotal,
    projectedRemaining: projectedRemaining,
    cumulativeSeries: cumulative,
  );
});