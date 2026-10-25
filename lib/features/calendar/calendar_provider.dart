import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../categories/categories_provider.dart';
import '../transactions/transactions_provider.dart';
import '../planned_expenses/planned_expenses_provider.dart';

enum CalendarEventType { income, expense, planned }

class CalendarEvent {
  final CalendarEventType type;
  final String label;
  final double amount;
  final String categoryName;

  CalendarEvent({
    required this.type,
    required this.label,
    required this.amount,
    required this.categoryName,
  });
}

DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

// Regroupe transactions réelles + dépenses planifiées, jour par jour
final calendarEventsProvider = Provider<Map<DateTime, List<CalendarEvent>>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final planned = ref.watch(plannedExpensesProvider).valueOrNull ?? [];
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

  String categoryName(int id) {
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return '...';
  }

  bool isExpenseCategory(int id) {
    for (final c in categories) {
      if (c.id == id) return c.type == 'expense';
    }
    return true;
  }

  final Map<DateTime, List<CalendarEvent>> events = {};

  for (final tx in transactions) {
    final key = _dayKey(tx.date);
    events.putIfAbsent(key, () => []).add(
      CalendarEvent(
        type: isExpenseCategory(tx.categoryId)
            ? CalendarEventType.expense
            : CalendarEventType.income,
        label: tx.label,
        amount: tx.amount,
        categoryName: categoryName(tx.categoryId),
      ),
    );
  }

  for (final pe in planned) {
    final key = _dayKey(pe.plannedDate);
    events.putIfAbsent(key, () => []).add(
      CalendarEvent(
        type: CalendarEventType.planned,
        label: pe.label,
        amount: pe.amount,
        categoryName: categoryName(pe.categoryId),
      ),
    );
  }

  return events;
});