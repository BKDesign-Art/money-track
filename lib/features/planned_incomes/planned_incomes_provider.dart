import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final plannedIncomesProvider = StreamProvider<List<PlannedIncome>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActivePlannedIncomes();
});