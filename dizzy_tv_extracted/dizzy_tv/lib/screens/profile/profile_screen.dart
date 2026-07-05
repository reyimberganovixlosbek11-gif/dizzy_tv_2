import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../saved/saved_screen.dart';
import '../settings/settings_screen.dart';
import '../admin/admin_login_screen.dart';
import 'edit_profile_screen.dart';
import 'history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _logoTapCount = 0;

  // Logotipga 5 marta ketma-ket bosilsa, admin panelga kirish ekrani ochiladi.
  // Bu oddiy foydalanuvchilar uchun ko'rinmas, lekin adminlar biladi.
  void _handleSecretTap() {
    _logoTapCount++;
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Kirish talab qilinadi', style: TextStyle(color: AppColors.textSecondary)))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() as Map<String, dynamic>?;
                  final name = data?['name'] ?? user.displayName ?? '';
                  final email = data?['email'] ?? user.email ?? '';
                  final photoUrl = data?['photoUrl'] ?? user.photoURL ?? '';

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _handleSecretTap,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.surface,
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person, size: 48, color: AppColors.textSecondary)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Center(
                        child: Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                      const SizedBox(height: 30),
                      _ProfileTile(
                        icon: Icons.edit,
                        title: 'Profilni tahrirlash',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                      ),
                      _ProfileTile(
                        icon: Icons.favorite_border,
                        title: 'Saqlangan kinolar',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedScreen())),
                      ),
                      _ProfileTile(
                        icon: Icons.history,
                        title: 'Ko\'rish tarixi',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      ),
                      _ProfileTile(
                        icon: Icons.settings,
                        title: 'Sozlamalar',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                      const SizedBox(height: 10),
                      _ProfileTile(
                        icon: Icons.logout,
                        title: 'Chiqish',
                        color: AppColors.error,
                        onTap: () async {
                          await AuthService().signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.title, this.color = AppColors.textPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color == AppColors.error ? AppColors.error : AppColors.primary),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
