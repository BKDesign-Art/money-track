import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileInfo {
  final String name;
  final String email;
  const ProfileInfo({required this.name, required this.email});
}

class ProfileNotifier extends Notifier<ProfileInfo> {
  @override
  ProfileInfo build() {
    _load();
    return const ProfileInfo(name: 'Utilisateur', email: 'non renseigné');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ProfileInfo(
      name: prefs.getString('profile_name') ?? 'Utilisateur',
      email: prefs.getString('profile_email') ?? 'non renseigné',
    );
  }

  Future<void> updateProfile({required String name, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email);
    state = ProfileInfo(name: name, email: email);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileInfo>(ProfileNotifier.new);