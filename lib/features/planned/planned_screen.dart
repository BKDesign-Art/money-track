import 'package:flutter/material.dart';
import '../planned_expenses/planned_expenses_screen.dart';
import '../planned_expenses/plan_expense_screen.dart';
import '../planned_incomes/planned_incomes_screen.dart';
import '../planned_incomes/plan_income_screen.dart';

class PlannedScreen extends StatelessWidget {
  const PlannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planifié'),
          bottom: const TabBar(tabs: [Tab(text: 'Dépenses'), Tab(text: 'Revenus')]),
        ),
        body: const TabBarView(children: [PlannedExpensesTab(), PlannedIncomesTab()]),
        floatingActionButton: const _PlannedFab(),
      ),
    );
  }
}

class _PlannedFab extends StatefulWidget {
  const _PlannedFab();
  @override
  State<_PlannedFab> createState() => _PlannedFabState();
}

class _PlannedFabState extends State<_PlannedFab> {
  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isExpenseTab = controller.index == 0;
        return FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isExpenseTab ? const PlanExpenseScreen() : const PlanIncomeScreen(),
            ),
          ),
          icon: const Icon(Icons.add),
          label: Text(isExpenseTab ? 'Dépense' : 'Revenu'),
        );
      },
    );
  }
}