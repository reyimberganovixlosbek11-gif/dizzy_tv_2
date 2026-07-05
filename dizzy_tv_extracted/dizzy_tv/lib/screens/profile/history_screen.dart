import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../movie/movie_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Ko\'rish tarixi')),
      body: SafeArea(
        child: uid == null
            ? const Center(child: Text('Kirish talab qilinadi', style: TextStyle(color: AppColors.textSecondary)))
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: firestoreService.watchHistoryStream(uid),
                builder: (context, histSnap) {
                  if (!histSnap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final history = histSnap.data!;
                  if (history.isEmpty) {
                    return const Center(child: Text('Hozircha hech narsa ko\'rmadingiz', style: TextStyle(color: AppColors.textSecondary)));
                  }
                  final ids = history.map((h) => h['movieId'] as String).toList();

                  return FutureBuilder<List<MovieModel>>(
                    future: firestoreService.getMoviesByIds(ids),
                    builder: (context, movieSnap) {
                      if (!movieSnap.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final movieMap = {for (var m in movieSnap.data!) m.id: m};
                      final orderedMovies = ids.where(movieMap.containsKey).map((id) => movieMap[id]!).toList();

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.6,
                        ),
                        itemCount: orderedMovies.length,
                        itemBuilder: (context, i) {
                          final movie = orderedMovies[i];
                          return MovieCard(
                            movie: movie,
                            width: double.infinity,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
