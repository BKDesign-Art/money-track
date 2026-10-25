import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../planned_expenses/plan_expense_screen.dart';
import 'calendar_provider.dart';

class FinancialCalendarScreen extends ConsumerStatefulWidget {
  const FinancialCalendarScreen({super.key});

  @override
  ConsumerState<FinancialCalendarScreen> createState() =>
      _FinancialCalendarScreenState();
}

class _FinancialCalendarScreenState
    extends ConsumerState<FinancialCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

  Color _colorFor(CalendarEvent event) {
    switch (event.type) {
      case CalendarEventType.income:
        return AppColors.income;
      case CalendarEventType.expense:
        return AppColors.expense;
      case CalendarEventType.planned:
        return Colors.blue;
    }
  }

  IconData _iconFor(CalendarEvent event) {
    switch (event.type) {
      case CalendarEventType.income:
        return Icons.arrow_upward;
      case CalendarEventType.expense:
        return Icons.arrow_downward;
      case CalendarEventType.planned:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(calendarEventsProvider);
    final selectedEvents = events[_dayKey(_selectedDay)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier financier')),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => events[_dayKey(day)] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, dayEvents) {
                if (dayEvents.isEmpty) return null;
                final colors = dayEvents.map(_colorFor).toSet().toList();
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: colors.take(3).map((c) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.income, 'Revenus'),
                const SizedBox(width: 16),
                _legendDot(AppColors.expense, 'Dépenses'),
                const SizedBox(width: 16),
                _legendDot(Colors.blue, 'Planifié'),
              ],
            ),
          ),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(child: Text('Aucun mouvement ce jour-là.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      final color = _colorFor(event);
                      final sign = event.type == CalendarEventType.expense
                          ? '-'
                          : event.type == CalendarEventType.income
                              ? '+'
                              : '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(30),
                          child: Icon(_iconFor(event), color: color, size: 18),
                        ),
                        title: Text(event.label),
                        subtitle: Text(event.categoryName),
                        trailing: Text(
                          '$sign${event.amount.toStringAsFixed(0)} FCFA',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanExpenseScreen(initialDate: _selectedDay),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}