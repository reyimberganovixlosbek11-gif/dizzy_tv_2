import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AdminBannersScreen extends StatelessWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bannerlar boshqaruvi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openBannerForm(context, firestoreService),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestoreService.bannersStream(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            final banners = snap.data!;
            if (banners.isEmpty) {
              return const Center(child: Text('Bannerlar yo\'q. "+" bosib qo\'shing', style: TextStyle(color: AppColors.textSecondary)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: banners.length,
              itemBuilder: (context, i) {
                final b = banners[i];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 60,
                        height: 40,
                        child: CachedNetworkImage(
                          imageUrl: b['imageUrl'] ?? '',
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => const Icon(Icons.image, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    title: Text(b['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(
                      (b['isActive'] ?? true) ? 'Faol' : 'Nofaol',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: b['isActive'] ?? true,
                          activeColor: AppColors.primary,
                          onChanged: (v) => firestoreService.updateBanner(b['id'], {'isActive': v}),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.gold, size: 20),
                          onPressed: () => _openBannerForm(context, firestoreService, banner: b),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                          onPressed: () => firestoreService.deleteBanner(b['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openBannerForm(BuildContext context, FirestoreService service, {Map<String, dynamic>? banner}) {
    final titleCtrl = TextEditingController(text: banner?['title'] ?? '');
    final imageCtrl = TextEditingController(text: banner?['imageUrl'] ?? '');
    final orderCtrl = TextEditingController(text: (banner?['order'] ?? 0).toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(banner == null ? 'Banner qo\'shish' : 'Bannerni tahrirlash',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Sarlavha', labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Rasm URL (Firebase Storage)', labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Tartib raqami', labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || imageCtrl.text.trim().isEmpty) {
                    Fluttertoast.showToast(msg: 'Sarlavha va rasm URL kerak');
                    return;
                  }
                  final data = {
                    'title': titleCtrl.text.trim(),
                    'imageUrl': imageCtrl.text.trim(),
                    'order': int.tryParse(orderCtrl.text) ?? 0,
                    'isActive': banner?['isActive'] ?? true,
                  };
                  if (banner == null) {
                    await service.addBanner(data);
                  } else {
                    await service.updateBanner(banner['id'], data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(banner == null ? 'Qo\'shish' : 'Saqlash'),
              ),
            ],
          ),
        );
      },
    );
  }
}
