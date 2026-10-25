import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final savingsGoalsProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSavingsGoals();
});

// Ajoute des calculs pratiques directement utilisables sur chaque objectif
extension SavingsGoalCalculations on SavingsGoal {
  double get progressRatio =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0, double.infinity);

  int? get daysRemaining {
    final date = targetDate;
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  double? get suggestedDailyAmount {
    final days = daysRemaining;
    if (days == null || days <= 0) return null;
    return remainingAmount / days;
  }

  double? get suggestedMonthlyAmount {
    final days = daysRemaining;
    if (days == null || days <= 0) return null;
    final months = days / 30.0;
    return remainingAmount / (months < 1 ? 1 : months);
  }
}