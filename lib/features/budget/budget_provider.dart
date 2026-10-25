import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../categories/categories_provider.dart';
import '../transactions/transactions_provider.dart';
import '../planned_expenses/planned_expenses_provider.dart';

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBudgets();
});

enum BudgetStatus { onTrack, watch, atRisk, exceeded }

class BudgetCategorySummary {
  final Category category;
  final double budgetLimit;
  final double realized;
  final double planned;

  BudgetCategorySummary({
    required this.category,
    required this.budgetLimit,
    required this.realized,
    required this.planned,
  });

  double get availableReal => budgetLimit - realized;
  double get remainingAfterPlanned => budgetLimit - realized - planned;

  BudgetStatus get status {
    if (realized > budgetLimit) return BudgetStatus.exceeded;
    if (realized + planned > budgetLimit) return BudgetStatus.atRisk;
    if (budgetLimit > 0 && realized / budgetLimit >= 0.8) return BudgetStatus.watch;
    return BudgetStatus.onTrack;
  }
}

bool _isThisMonth(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}

final budgetSummaryProvider = Provider<List<BudgetCategorySummary>>((ref) {
  final budgetList = ref.watch(budgetsProvider).value ?? [];
  final categories = ref.watch(categoriesProvider).value ?? [];
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final planned = ref.watch(plannedExpensesProvider).value ?? [];

  Category? findCategory(int id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  final summaries = <BudgetCategorySummary>[];

  for (final budget in budgetList) {
    final category = findCategory(budget.categoryId);
    if (category == null) continue;

    final realized = transactions
        .where((t) => t.categoryId == budget.categoryId && _isThisMonth(t.date))
        .fold<double>(0, (sum, t) => sum + t.amount);

    final plannedAmount = planned
        .where((pe) => pe.categoryId == budget.categoryId && _isThisMonth(pe.plannedDate))
        .fold<double>(0, (sum, pe) => sum + pe.amount);

    summaries.add(BudgetCategorySummary(
      category: category,
      budgetLimit: budget.monthlyLimit,
      realized: realized,
      planned: plannedAmount,
    ));
  }

  return summaries;
});

// ---------- VUE D'ENSEMBLE GLOBALE ----------

class BudgetOverview {
  final double totalRealized;
  final double totalBudget;
  final double dailyAverage;
  final List<double> dailySeries;

  BudgetOverview({
    required this.totalRealized,
    required this.totalBudget,
    required this.dailyAverage,
    required this.dailySeries,
  });

  double get ratio => totalBudget > 0 ? (totalRealized / totalBudget).clamp(0.0, 1.0) : 0.0;
}

final budgetOverviewProvider = Provider<BudgetOverview>((ref) {
  final summaries = ref.watch(budgetSummaryProvider);
  final transactions = ref.watch(transactionsProvider).value ?? [];

  final totalRealized = summaries.fold<double>(0, (sum, s) => sum + s.realized);
  final totalBudget = summaries.fold<double>(0, (sum, s) => sum + s.budgetLimit);
  final budgetedCategoryIds = summaries.map((s) => s.category.id).toSet();

  final now = DateTime.now();
  final daysElapsed = now.day;
  final dailyTotals = List<double>.filled(daysElapsed, 0);

  for (final t in transactions) {
    if (t.date.year == now.year &&
        t.date.month == now.month &&
        budgetedCategoryIds.contains(t.categoryId)) {
      final dayIndex = t.date.day - 1;
      if (dayIndex >= 0 && dayIndex < daysElapsed) {
        dailyTotals[dayIndex] += t.amount;
      }
    }
  }

  return BudgetOverview(
    totalRealized: totalRealized,
    totalBudget: totalBudget,
    dailyAverage: daysElapsed > 0 ? totalRealized / daysElapsed : 0.0,
    dailySeries: dailyTotals,
  );
});