import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../movie/movie_detail_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Saqlanganlar')),
      body: SafeArea(
        child: uid == null
            ? const Center(child: Text('Kirish talab qilinadi', style: TextStyle(color: AppColors.textSecondary)))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final data = userSnap.data!.data() as Map<String, dynamic>?;
                  final savedIds = List<String>.from(data?['savedMovieIds'] ?? []);

                  if (savedIds.isEmpty) {
                    return const Center(
                      child: Text('Saqlangan kinolar yo\'q', style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }

                  return FutureBuilder<List<MovieModel>>(
                    future: firestoreService.getMoviesByIds(savedIds),
                    builder: (context, movieSnap) {
                      if (!movieSnap.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final movies = movieSnap.data!;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.6,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (context, i) {
                          final movie = movies[i];
                          return Stack(
                            children: [
                              MovieCard(
                                movie: movie,
                                width: double.infinity,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => firestoreService.toggleSaved(uid, movie.id, true),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
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
