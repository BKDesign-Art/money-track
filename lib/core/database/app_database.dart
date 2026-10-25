import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
part 'app_database.g.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get type => text().withDefault(const Constant('cash'))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get note => text().nullable()();
}

class PlannedExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  RealColumn get amount => real()();
  DateTimeColumn get plannedDate => dateTime()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  TextColumn get note => text().nullable()();
  IntColumn get linkedTransactionId => integer().nullable().references(Transactions, #id)();
}

class PlannedIncomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  RealColumn get amount => real()();
  DateTimeColumn get plannedDate => dateTime()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  TextColumn get note => text().nullable()();
  IntColumn get linkedTransactionId => integer().nullable().references(Transactions, #id)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  RealColumn get monthlyLimit => real()();
}

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
}

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, PlannedExpenses, PlannedIncomes, Budgets, SavingsGoals],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(plannedExpenses);
          if (from < 3) await m.createTable(budgets);
          if (from < 4) await m.createTable(savingsGoals);
         if (from < 5) await m.addColumn(transactions, transactions.note as GeneratedColumn<Object>);
if (from < 6) await m.addColumn(accounts, accounts.type as GeneratedColumn<Object>);
          if (from < 7) await m.createTable(PlannedIncomes() as TableInfo<Table, dynamic>);
        },
      );


  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();

  Future<int> addAccount(String name, double balance, String type) {
    return into(accounts).insert(
      AccountsCompanion.insert(name: name, balance: Value(balance), type: Value(type)),
    );
  }

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<int> addCategory(String name, String type) {
    return into(categories).insert(CategoriesCompanion.insert(name: name, type: type));
  }

  Future<void> ensureDefaultCategories() async {
    final existing = await select(categories).get();
    if (existing.isNotEmpty) return;

    const defaults = [
      ('Alimentation', 'expense'),
      ('Transport', 'expense'),
      ('Logement', 'expense'),
      ('Santé', 'expense'),
      ('Loisirs', 'expense'),
      ('Scolarité', 'expense'),
      ('Autres dépenses', 'expense'),
      ('Salaire', 'income'),
      ('Bourse', 'income'),
      ('Aide familiale', 'income'),
      ('Autres revenus', 'income'),
    ];
    for (final (name, type) in defaults) {
      await addCategory(name, type);
    }
  }

  Future<void> ensureTransferCategory() async {
    final existing = await (select(categories)..where((c) => c.type.equals('transfer'))).getSingleOrNull();
    if (existing != null) return;
    await addCategory('Transfert', 'transfer');
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  Future<void> addTransaction({
    required String label,
    required double amount,
    required DateTime date,
    required int accountId,
    required int categoryId,
    required bool isExpense,
    String? note,
  }) async {
    await transaction(() async {
      await into(transactions).insert(TransactionsCompanion.insert(
        label: label, amount: amount, date: date, accountId: accountId, categoryId: categoryId, note: Value(note),
      ));
      final account = await (select(accounts)..where((a) => a.id.equals(accountId))).getSingle();
      final newBalance = isExpense ? account.balance - amount : account.balance + amount;
      await (update(accounts)..where((a) => a.id.equals(accountId)))
          .write(AccountsCompanion(balance: Value(newBalance)));
    });
  }

  Future<void> updateTransaction({
    required int id,
    required String label,
    required double amount,
    required DateTime date,
    required int accountId,
    required int categoryId,
    required bool isExpense,
    String? note,
  }) async {
    await transaction(() async {
      final old = await (select(transactions)..where((t) => t.id.equals(id))).getSingle();
      final oldCategory = await (select(categories)..where((c) => c.id.equals(old.categoryId))).getSingleOrNull();
      final oldWasExpense = oldCategory?.type == 'expense';
      final oldAccount = await (select(accounts)..where((a) => a.id.equals(old.accountId))).getSingle();
      final revertedBalance = oldWasExpense ? oldAccount.balance + old.amount : oldAccount.balance - old.amount;
      await (update(accounts)..where((a) => a.id.equals(old.accountId)))
          .write(AccountsCompanion(balance: Value(revertedBalance)));
      final newAccount = await (select(accounts)..where((a) => a.id.equals(accountId))).getSingle();
      final newBalance = isExpense ? newAccount.balance - amount : newAccount.balance + amount;
      await (update(accounts)..where((a) => a.id.equals(accountId)))
          .write(AccountsCompanion(balance: Value(newBalance)));
     await (update(transactions)..where((t) => t.id.equals(id))).write(
  TransactionsCompanion(
    label: Value(label),
    amount: Value(amount),
    date: Value(date),
    accountId: Value(accountId),
    categoryId: Value(categoryId),
    id: Value(note as int),
  ),
);
    });
  }

  Future<void> deleteTransaction(int id) async {
    await transaction(() async {
      final tx = await (select(transactions)..where((t) => t.id.equals(id))).getSingle();
      final category = await (select(categories)..where((c) => c.id.equals(tx.categoryId))).getSingleOrNull();

      if (category?.type == 'transfer') {
        final pair = await (select(transactions)
              ..where((t) =>
                  t.categoryId.equals(tx.categoryId) &
                  t.amount.equals(tx.amount) &
                  t.date.equals(tx.date) &
                  t.id.equals(id).not()))
            .getSingleOrNull();
        final account = await (select(accounts)..where((a) => a.id.equals(tx.accountId))).getSingle();
        final isOutgoing = tx.label.startsWith('Transfert vers');
        final reverted = isOutgoing ? account.balance + tx.amount : account.balance - tx.amount;
        await (update(accounts)..where((a) => a.id.equals(tx.accountId)))
            .write(AccountsCompanion(balance: Value(reverted)));
        await (delete(transactions)..where((t) => t.id.equals(id))).go();
        if (pair != null) {
          final pairAccount = await (select(accounts)..where((a) => a.id.equals(pair.accountId))).getSingle();
          final pairIsOutgoing = pair.label.startsWith('Transfert vers');
          final pairReverted =
              pairIsOutgoing ? pairAccount.balance + pair.amount : pairAccount.balance - pair.amount;
          await (update(accounts)..where((a) => a.id.equals(pair.accountId)))
              .write(AccountsCompanion(balance: Value(pairReverted)));
          await (delete(transactions)..where((t) => t.id.equals(pair.id))).go();
        }
        return;
      }

      final wasExpense = category?.type == 'expense';
      final account = await (select(accounts)..where((a) => a.id.equals(tx.accountId))).getSingle();
      final reverted = wasExpense ? account.balance + tx.amount : account.balance - tx.amount;
      await (update(accounts)..where((a) => a.id.equals(tx.accountId)))
          .write(AccountsCompanion(balance: Value(reverted)));
      await (delete(transactions)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> addTransfer({
    required double amount,
    required DateTime date,
    required int fromAccountId,
    required int toAccountId,
    String? note,
  }) async {
    await transaction(() async {
      final transferCategory = await (select(categories)..where((c) => c.type.equals('transfer'))).getSingle();
      final fromAccount = await (select(accounts)..where((a) => a.id.equals(fromAccountId))).getSingle();
      final toAccount = await (select(accounts)..where((a) => a.id.equals(toAccountId))).getSingle();

      await into(transactions).insert(TransactionsCompanion.insert(
        label: 'Transfert vers ${toAccount.name}', amount: amount, date: date,
        accountId: fromAccountId, categoryId: transferCategory.id, note: Value(note),
      ));
      await into(transactions).insert(TransactionsCompanion.insert(
        label: 'Transfert depuis ${fromAccount.name}', amount: amount, date: date,
        accountId: toAccountId, categoryId: transferCategory.id, note: Value(note),
      ));

      await (update(accounts)..where((a) => a.id.equals(fromAccountId)))
          .write(AccountsCompanion(balance: Value(fromAccount.balance - amount)));
      await (update(accounts)..where((a) => a.id.equals(toAccountId)))
          .write(AccountsCompanion(balance: Value(toAccount.balance + amount)));
    });
  }

  Stream<List<PlannedExpense>> watchActivePlannedExpenses() {
    return (select(plannedExpenses)
          ..where((pe) => pe.status.equals('planned'))
          ..orderBy([(pe) => OrderingTerm.asc(pe.plannedDate)]))
        .watch();
  }

  Future<int> addPlannedExpense({
    required String label,
    required double amount,
    required DateTime plannedDate,
    required int accountId,
    required int categoryId,
    String priority = 'medium',
    String? note,
  }) {
    return into(plannedExpenses).insert(PlannedExpensesCompanion.insert(
      label: label, amount: amount, plannedDate: plannedDate,
      accountId: accountId, categoryId: categoryId, priority: Value(priority), note: Value(note),
    ));
  }

  Future<void> convertPlannedExpenseToTransaction(int plannedExpenseId) async {
    await transaction(() async {
      final planned = await (select(plannedExpenses)..where((pe) => pe.id.equals(plannedExpenseId))).getSingle();
      final txId = await into(transactions).insert(TransactionsCompanion.insert(
        label: planned.label, amount: planned.amount, date: planned.plannedDate,
       accountId: planned.accountId,
categoryId: planned.categoryId,
note: const Value(null),
      ));
      final account = await (select(accounts)..where((a) => a.id.equals(planned.accountId))).getSingle();
      await (update(accounts)..where((a) => a.id.equals(planned.accountId)))
          .write(AccountsCompanion(balance: Value(account.balance - planned.amount)));
      await (update(plannedExpenses)..where((pe) => pe.id.equals(plannedExpenseId))).write(
        PlannedExpensesCompanion(status: const Value('completed'), linkedTransactionId: Value(txId)),
      );
    });
  }

  Future<void> cancelPlannedExpense(int plannedExpenseId) {
    return (update(plannedExpenses)..where((pe) => pe.id.equals(plannedExpenseId)))
        .write(const PlannedExpensesCompanion(status: Value('cancelled')));
  }

  Stream<List<dynamic>> watchActivePlannedIncomes() {
    return (select(plannedIncomes)
          ..where((pi) => pi.status.equals('planned'))
          ..orderBy([(pi) => OrderingTerm.asc(pi.plannedDate)]))
        .watch();
  }

  Future<int> addPlannedIncome({ 
    required String label,
    required double amount,
    required DateTime plannedDate,
    required int accountId,
    required int categoryId,
    String? note,
  }) {
    return into(PlannedIncomes() as TableInfo<Table, dynamic>).insert(PlannedIncomesCompanion.insert(
      label: label, amount: amount, plannedDate: plannedDate,
      accountId: accountId, categoryId: categoryId, note: Value(note),
    ));
  }

 Future<void> convertPlannedIncomeToTransaction(
    int plannedIncomeId) async {
  await transaction(() async {
    final planned = await (select(plannedIncomes)
          ..where((pi) => pi.id.equals(plannedIncomeId)))
        .getSingle();

    final txId = await into(transactions).insert(
      TransactionsCompanion.insert(
        label: planned.label,
        amount: planned.amount,
        date: planned.plannedDate,
        accountId: planned.accountId,
        categoryId: planned.categoryId, note:,
      ),
    );

    final account = await (select(accounts)
          ..where((a) => a.id.equals(planned.accountId)))
        .getSingle();

    await (update(accounts)
          ..where((a) => a.id.equals(planned.accountId)))
        .write(
      AccountsCompanion(
        balance: Value(account.balance + planned.amount),
      ),
    );

    await (update(plannedIncomes)
          ..where((pi) => pi.id.equals(plannedIncomeId)))
        .write(
      PlannedIncomesCompanion(
        status: const Value('completed'),
        linkedTransactionId: Value(txId),
      ),
    );
  });
}

 Future<void> cancelPlannedIncome(int plannedIncomeId) {
  return (update(plannedIncomes)
        ..where((pi) => pi.id.equals(plannedIncomeId)))
      .write(
    const PlannedIncomesCompanion(
      status: Value('cancelled'),
    ),
  );
}

  Stream<List<Budget>> watchAllBudgets() => select(budgets).watch();

  Future<void> setBudget(int categoryId, double amount) async {
    final existing = await (select(budgets)..where((b) => b.categoryId.equals(categoryId))).getSingleOrNull();
    if (existing == null) {
      await into(budgets).insert(BudgetsCompanion.insert(categoryId: categoryId, monthlyLimit: amount));
    } else {
      await (update(budgets)..where((b) => b.id.equals(existing.id)))
          .write(BudgetsCompanion(monthlyLimit: Value(amount)));
    }
  }

  Stream<List<SavingsGoal>> watchAllSavingsGoals() => select(savingsGoals).watch();

  Future<int> addSavingsGoal({required String name, required double targetAmount, DateTime? targetDate}) {
    return into(savingsGoals)
        .insert(SavingsGoalsCompanion.insert(name: name, targetAmount: targetAmount, targetDate: Value(targetDate)));
  }

  Future<void> addMoneyToGoal({required int goalId, required double amount, required int accountId}) async {
    await transaction(() async {
      final goal = await (select(savingsGoals)..where((g) => g.id.equals(goalId))).getSingle();
      await (update(savingsGoals)..where((g) => g.id.equals(goalId)))
          .write(SavingsGoalsCompanion(savedAmount: Value(goal.savedAmount + amount)));
      final account = await (select(accounts)..where((a) => a.id.equals(accountId))).getSingle();
      await (update(accounts)..where((a) => a.id.equals(accountId)))
          .write(AccountsCompanion(balance: Value(account.balance - amount)));
    });
  }

  Future<void> deleteSavingsGoal(int goalId) {
    return (delete(savingsGoals)..where((g) => g.id.equals(goalId))).go();
  }
}
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'money_track.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}