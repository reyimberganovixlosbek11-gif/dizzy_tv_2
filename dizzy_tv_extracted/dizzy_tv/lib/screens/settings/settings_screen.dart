import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SettingsTile(icon: Icons.language, title: 'Til', subtitle: 'O\'zbekcha', onTap: () {}),
            _SettingsTile(icon: Icons.notifications_none, title: 'Bildirishnomalar', onTap: () {}),
            _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Maxfiylik siyosati', onTap: () {}),
            _SettingsTile(icon: Icons.description_outlined, title: 'Foydalanish shartlari', onTap: () {}),
            _SettingsTile(icon: Icons.info_outline, title: 'Ilova haqida', subtitle: 'Dizzy.tv v1.0.0', onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary)) : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
