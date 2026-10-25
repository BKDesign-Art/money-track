import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import 'account_type.dart';
import 'accounts_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes comptes')),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun compte pour le moment.\nAjoute-en un avec le bouton +',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final total = accounts.fold<double>(0, (sum, a) => sum + a.balance);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final info = accountTypeInfo(account.type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: info.color.withAlpha(30), shape: BoxShape.circle),
                              child: Icon(info.icon, color: info.color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(info.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text('${account.balance.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SoftCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Solde total', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${total.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = accountTypes.first.value;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nouveau compte'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom du compte'),
                  ),
                  TextField(
                    controller: balanceController,
                    decoration: const InputDecoration(labelText: 'Solde initial (FCFA)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Type de compte', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: accountTypes.map((t) {
                      final selected = t.value == selectedType;
                      return GestureDetector(
                        onTap: () => setState(() => selectedType = t.value),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: selected ? t.color : t.color.withAlpha(25),
                                shape: BoxShape.circle,
                                border: selected ? Border.all(color: t.color, width: 2) : null,
                              ),
                              child: Icon(t.icon, color: selected ? Colors.white : t.color),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 64,
                              child: Text(t.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final balance = double.tryParse(balanceController.text) ?? 0;
                    if (name.isEmpty) return;

                    final db = ref.read(databaseProvider);
                    await db.addAccount(name, balance, selectedType);

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}