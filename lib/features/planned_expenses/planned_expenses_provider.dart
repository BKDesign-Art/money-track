import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final plannedExpensesProvider = StreamProvider<List<PlannedExpense>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActivePlannedExpenses();
});