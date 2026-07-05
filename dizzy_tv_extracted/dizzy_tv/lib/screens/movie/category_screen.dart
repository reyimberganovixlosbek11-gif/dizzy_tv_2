import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../movie/movie_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String genreName;
  const CategoryScreen({super.key, required this.genreName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _firestoreService = FirestoreService();
  List<MovieModel>? _movies;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await _firestoreService.searchMovies(genre: widget.genreName);
    if (mounted) setState(() => _movies = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.genreName)),
      body: SafeArea(
        child: _movies == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _movies!.isEmpty
                ? const Center(child: Text('Bu janrda kino yo\'q', style: TextStyle(color: AppColors.textSecondary)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: _movies!.length,
                    itemBuilder: (context, i) {
                      final movie = _movies![i];
                      return MovieCard(
                        movie: movie,
                        width: double.infinity,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
