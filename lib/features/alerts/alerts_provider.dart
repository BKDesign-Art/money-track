import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/dashboard_provider.dart';
import '../planned_expenses/planned_expenses_provider.dart';

enum AlertSeverity { warning, danger }

class TimelineAlert {
  final AlertSeverity severity;
  final String title;
  final String description;
  final DateTime date;

  TimelineAlert({
    required this.severity,
    required this.title,
    required this.description,
    required this.date,
  });
}

String _formatDate(DateTime date) {
  const months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
  ];
  return '${date.day} ${months[date.month - 1]}';
}

final timelineAlertsProvider = Provider<List<TimelineAlert>>((ref) {
  final totalBalance = ref.watch(totalBalanceProvider);
  final planned = ref.watch(plannedExpensesProvider).valueOrNull ?? [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Seulement les dépenses à venir (aujourd'hui inclus), triées chronologiquement
  final upcoming = planned.where((e) => !e.plannedDate.isBefore(today)).toList()
    ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));

  final alerts = <TimelineAlert>[];

  // ---------- Risque de découvert projeté ----------
  double runningBalance = totalBalance;
  for (final expense in upcoming) {
    runningBalance -= expense.amount;
    if (runningBalance < 0) {
      alerts.add(TimelineAlert(
        severity: AlertSeverity.danger,
        title: 'Risque de découvert',
        description:
            'Après "${expense.label}" le ${_formatDate(expense.plannedDate)}, '
            'ton solde projeté serait de ${runningBalance.toStringAsFixed(0)} FCFA.',
        date: expense.plannedDate,
      ));
      break; // on ne signale que le premier creux, pour ne pas noyer l'utilisateur
    }
  }

  // ---------- Semaine chargée (3+ dépenses en 7 jours) ----------
  for (final start in upcoming) {
    final windowEnd = start.plannedDate.add(const Duration(days: 7));
    final countInWindow = upcoming
        .where((e) =>
            !e.plannedDate.isBefore(start.plannedDate) &&
            e.plannedDate.isBefore(windowEnd))
        .length;

    if (countInWindow >= 3) {
      alerts.add(TimelineAlert(
        severity: AlertSeverity.warning,
        title: 'Semaine chargée',
        description:
            '$countInWindow dépenses planifiées entre le ${_formatDate(start.plannedDate)} '
            'et le ${_formatDate(windowEnd)}.',
        date: start.plannedDate,
      ));
      break; // une seule alerte de ce type, la plus proche dans le temps
    }
  }

  return alerts;
});