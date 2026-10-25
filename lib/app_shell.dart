import 'package:flutter/material.dart';
import 'core/responsive/responsive.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/planned/planned_screen.dart';
import 'features/calendar/financial_calendar_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/savings_goals/savings_goals_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    AccountsScreen(),
    TransactionsScreen(),
    PlannedScreen(),
    FinancialCalendarScreen(),
    BudgetScreen(),
    SavingsGoalsScreen(),
  ];

  static const _destinations = [
    (icon: Icons.home, label: 'Accueil'),
    (icon: Icons.account_balance_wallet, label: 'Comptes'),
    (icon: Icons.list_alt, label: 'Transactions'),
    (icon: Icons.event_note, label: 'Planifié'),
    (icon: Icons.calendar_month, label: 'Calendrier'),
    (icon: Icons.pie_chart, label: 'Budget'),
    (icon: Icons.savings, label: 'Objectifs'),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _destinations.map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label)).toList(),
      ),
    );
  }
}