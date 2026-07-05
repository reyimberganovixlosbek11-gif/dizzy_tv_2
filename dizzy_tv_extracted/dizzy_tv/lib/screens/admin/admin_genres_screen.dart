import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';

class AdminGenresScreen extends StatelessWidget {
  const AdminGenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriyalar (janrlar)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openGenreDialog(context, firestoreService),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<GenreModel>>(
          stream: firestoreService.genres(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            final genres = snap.data!;
            if (genres.isEmpty) {
              return const Center(child: Text('Janrlar yo\'q. "+" bosib qo\'shing', style: TextStyle(color: AppColors.textSecondary)));
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: genres.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                final reordered = List<GenreModel>.from(genres);
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                for (int i = 0; i < reordered.length; i++) {
                  await firestoreService.updateGenre(reordered[i].id, {'order': i});
                }
              },
              itemBuilder: (context, i) {
                final g = genres[i];
                return Card(
                  key: ValueKey(g.id),
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                    title: Text(g.name, style: const TextStyle(color: AppColors.textPrimary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.gold, size: 20),
                          onPressed: () => _openGenreDialog(context, firestoreService, genre: g),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                          onPressed: () => firestoreService.deleteGenre(g.id),
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

  void _openGenreDialog(BuildContext context, FirestoreService service, {GenreModel? genre}) {
    final nameCtrl = TextEditingController(text: genre?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(genre == null ? 'Janr qo\'shish' : 'Janrni tahrirlash', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Masalan: Drama, Komediya'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                Fluttertoast.showToast(msg: 'Nomini kiriting');
                return;
              }
              if (genre == null) {
                await service.addGenre(GenreModel(id: '', name: nameCtrl.text.trim()));
              } else {
                await service.updateGenre(genre.id, {'name': nameCtrl.text.trim()});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }
}
