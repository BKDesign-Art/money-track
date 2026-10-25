import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';

class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle({required this.icon, required this.color});
}

const Map<String, CategoryStyle> _knownStyles = {
  'Alimentation': CategoryStyle(icon: Icons.restaurant, color: Color(0xFFFF6B6B)),
  'Transport': CategoryStyle(icon: Icons.directions_car, color: Color(0xFFFF922B)),
  'Logement': CategoryStyle(icon: Icons.home, color: Color(0xFFE03131)),
  'Santé': CategoryStyle(icon: Icons.medical_services, color: Color(0xFF12B886)),
  'Loisirs': CategoryStyle(icon: Icons.sports_esports, color: Color(0xFFBE4BDB)),
  'Scolarité': CategoryStyle(icon: Icons.school, color: Color(0xFF7048E8)),
  'Autres dépenses': CategoryStyle(icon: Icons.receipt_long, color: Color(0xFF868E96)),
  'Salaire': CategoryStyle(icon: Icons.work, color: Color(0xFF2F9E44)),
  'Bourse': CategoryStyle(icon: Icons.card_giftcard, color: Color(0xFF1FAE66)),
  'Aide familiale': CategoryStyle(icon: Icons.family_restroom, color: Color(0xFF2F6FED)),
  'Autres revenus': CategoryStyle(icon: Icons.attach_money, color: Color(0xFF37B24D)),
};

const _fallbackPalette = [
  Color(0xFF1FAE66), Color(0xFF2F6FED), Color(0xFFBE4BDB),
  Color(0xFFFF922B), Color(0xFF12B886), Color(0xFFE03131),
];

CategoryStyle categoryStyleFor(Category category) {
  final known = _knownStyles[category.name];
  if (known != null) return known;
  final color = _fallbackPalette[category.name.hashCode.abs() % _fallbackPalette.length];
  final icon = category.type == 'income' ? Icons.attach_money : Icons.category;
  return CategoryStyle(icon: icon, color: color);
}