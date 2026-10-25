import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../categories/categories_screen.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(profile.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditProfileDialog(context, ref, profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard([
            _tile(Icons.person_outline, 'Informations personnelles',
                onTap: () => _showEditProfileDialog(context, ref, profile)),
            _tile(Icons.lock_outline, 'Sécurité', onTap: () => _comingSoon(context)),
            _tile(Icons.tune, 'Préférences', onTap: () => _comingSoon(context)),
            _tile(Icons.category_outlined, 'Catégories',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const CategoriesScreen()))),
          ]),
          const SizedBox(height: 12),
          _sectionCard([
            _tile(Icons.attach_money, 'Devise', trailing: 'FCFA'),
            _tile(Icons.sync, 'Sauvegarde & synchronisation', trailing: 'Locale uniquement'),
            _tile(Icons.info_outline, 'À propos de MoneyTrack', onTap: () => _showAbout(context)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
              onPressed: () => _comingSoon(context),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(List<Widget> tiles) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: trailing != null
          ? Text(trailing, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))
          : (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textSecondary) : null),
      onTap: onTap,
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Fonctionnalité à venir dans une prochaine version.')));
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MoneyTrack',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.trending_up, color: Colors.white),
      ),
      children: const [
        SizedBox(height: 12),
        Text('Application de gestion financière personnelle, pensée pour les étudiants.'),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, ProfileInfo profile) {
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await ref.read(profileProvider.notifier).updateProfile(
                    name: nameController.text.trim().isEmpty ? 'Utilisateur' : nameController.text.trim(),
                    email: emailController.text.trim().isEmpty ? 'non renseigné' : emailController.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}