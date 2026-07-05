import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';
import 'admin_movie_form_screen.dart';

enum _MovieFilter { all, active, inactive, banner, newest, mostViewed }

class AdminMoviesScreen extends StatefulWidget {
  const AdminMoviesScreen({super.key});

  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  final _firestoreService = FirestoreService();
  final _searchCtrl = TextEditingController();
  _MovieFilter _filter = _MovieFilter.all;

  List<MovieModel> _applyFilter(List<MovieModel> movies) {
    var result = List<MovieModel>.from(movies);
    final kw = _searchCtrl.text.trim().toLowerCase();
    if (kw.isNotEmpty) {
      result = result.where((m) => m.title.toLowerCase().contains(kw)).toList();
    }
    switch (_filter) {
      case _MovieFilter.active:
        result = result.where((m) => m.isActive).toList();
        break;
      case _MovieFilter.inactive:
        result = result.where((m) => !m.isActive).toList();
        break;
      case _MovieFilter.banner:
        result = result.where((m) => m.isBanner).toList();
        break;
      case _MovieFilter.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _MovieFilter.mostViewed:
        result.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
        break;
      case _MovieFilter.all:
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinolar boshqaruvi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminMovieFormScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Kino qidirish...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'Barchasi', selected: _filter == _MovieFilter.all, onTap: () => setState(() => _filter = _MovieFilter.all)),
                    _FilterChip(label: 'Faol', selected: _filter == _MovieFilter.active, onTap: () => setState(() => _filter = _MovieFilter.active)),
                    _FilterChip(label: 'Nofaol', selected: _filter == _MovieFilter.inactive, onTap: () => setState(() => _filter = _MovieFilter.inactive)),
                    _FilterChip(label: 'Banner', selected: _filter == _MovieFilter.banner, onTap: () => setState(() => _filter = _MovieFilter.banner)),
                    _FilterChip(label: 'Yangi', selected: _filter == _MovieFilter.newest, onTap: () => setState(() => _filter = _MovieFilter.newest)),
                    _FilterChip(label: 'Eng ko\'p ko\'rilgan', selected: _filter == _MovieFilter.mostViewed, onTap: () => setState(() => _filter = _MovieFilter.mostViewed)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<MovieModel>>(
                stream: _firestoreService.allMoviesAdmin(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final movies = _applyFilter(snap.data!);
                  if (movies.isEmpty) {
                    return const Center(child: Text('Kino topilmadi', style: TextStyle(color: AppColors.textSecondary)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: movies.length,
                    itemBuilder: (context, i) {
                      final m = movies[i];
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 42,
                              height: 60,
                              child: CachedNetworkImage(
                                imageUrl: m.posterUrl,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => const Icon(Icons.movie, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          title: Text(m.title, style: const TextStyle(color: AppColors.textPrimary)),
                          subtitle: Text(
                            '${m.year} • ${m.viewsCount} ko\'rish • ${m.isActive ? "Faol" : "Nofaol"}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.gold, size: 20),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminMovieFormScreen(movie: m)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                onPressed: () => _confirmDelete(context, m),
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
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MovieModel movie) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('O\'chirish', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('"${movie.title}" o\'chirilsinmi?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              _firestoreService.deleteMovie(movie.id);
              Navigator.pop(ctx);
            },
            child: const Text('O\'chirish', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}
