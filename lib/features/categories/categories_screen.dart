import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/widgets/soft_card.dart';
import 'categories_provider.dart';
import 'category_style.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      body: categoriesAsync.when(
        data: (categories) {
          final expenseCategories = categories.where((c) => c.type == 'expense').toList();
          final incomeCategories = categories.where((c) => c.type == 'income').toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              const Text('Dépenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ...expenseCategories.map(_categoryTile),
              const SizedBox(height: 20),
              const Text('Revenus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ...incomeCategories.map(_categoryTile),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _categoryTile(Category category) {
    final style = categoryStyleFor(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: style.color.withAlpha(30), shape: BoxShape.circle),
              child: Icon(style.icon, color: style.color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nouvelle catégorie'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Dépense'),
                        selected: selectedType == 'expense',
                        onSelected: (_) => setState(() => selectedType = 'expense'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Revenu'),
                        selected: selectedType == 'income',
                        onSelected: (_) => setState(() => selectedType = 'income'),
                      ),
                    ),
                  ]),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    await ref.read(databaseProvider).addCategory(name, selectedType);
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