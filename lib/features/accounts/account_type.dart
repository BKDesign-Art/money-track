import 'package:flutter/material.dart';

class AccountTypeInfo {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const AccountTypeInfo({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const accountTypes = [
  AccountTypeInfo(value: 'cash', label: 'Espèces', icon: Icons.payments, color: Color(0xFF1FAE66)),
  AccountTypeInfo(value: 'mobile_money', label: 'Mobile Money', icon: Icons.phone_android, color: Color(0xFFFFB300)),
  AccountTypeInfo(value: 'orange_money', label: 'Orange Money', icon: Icons.phone_android, color: Color(0xFFFF7A00)),
  AccountTypeInfo(value: 'bank', label: 'Compte bancaire', icon: Icons.account_balance, color: Color(0xFF2F6FED)),
];

AccountTypeInfo accountTypeInfo(String value) {
  for (final t in accountTypes) {
    if (t.value == value) return t;
  }
  return accountTypes.first;
}