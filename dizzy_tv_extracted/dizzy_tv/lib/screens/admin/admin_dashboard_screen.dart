import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_login_screen.dart';
import 'admin_movies_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_genres_screen.dart';

/// Admin panel bosh sahifasi: statistikalar + boshqaruv bo'limlariga link.
/// Kino/Banner/Janr CRUD ekranlari keyingi bosqichda to'liq quriladi —
/// bu yerda ularga o'tish tugmalari va real vaqtli statistikalar tayyor.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistika', style: TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: db.collection('movies').snapshots(),
                builder: (context, snap) {
                  final total = snap.data?.docs.length ?? 0;
                  final active = snap.data?.docs
                          .where((d) => (d.data() as Map)['isActive'] == true)
                          .length ??
                      0;
                  int totalViews = 0;
                  if (snap.hasData) {
                    for (var d in snap.data!.docs) {
                      totalViews += ((d.data() as Map)['viewsCount'] ?? 0) as int;
                    }
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(title: 'Jami kinolar', value: '$total', icon: Icons.movie),
                      _StatCard(title: 'Faol kinolar', value: '$active', icon: Icons.check_circle),
                      _StatCard(title: 'Jami ko\'rishlar', value: '$totalViews', icon: Icons.visibility),
                      _StatCard(title: 'Bannerlar', value: '-', icon: Icons.image),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              const Text('Boshqaruv', style: TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _AdminMenuTile(
                icon: Icons.movie_creation,
                title: 'Kinolar boshqaruvi',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMoviesScreen())),
              ),
              _AdminMenuTile(
                icon: Icons.image,
                title: 'Bannerlar boshqaruvi',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBannersScreen())),
              ),
              _AdminMenuTile(
                icon: Icons.category,
                title: 'Kategoriyalar (janrlar)',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGenresScreen())),
              ),
              const SizedBox(height: 20),
              const Text('So\'nggi 5 ta kino', style: TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: db.collection('movies').orderBy('createdAt', descending: true).limit(5).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('Hozircha kino yo\'q', style: TextStyle(color: AppColors.textSecondary));
                  }
                  return Column(
                    children: docs.map((d) {
                      final m = d.data() as Map<String, dynamic>;
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.movie, color: AppColors.primary),
                          title: Text(m['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary)),
                          subtitle: Text('${m['year'] ?? ''} • ${m['viewsCount'] ?? 0} ko\'rish',
                              style: const TextStyle(color: AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.primary),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _AdminMenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
