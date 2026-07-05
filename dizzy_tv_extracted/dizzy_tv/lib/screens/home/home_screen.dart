import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/movie_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/section_title.dart';
import '../search/search_screen.dart';
import '../movie/movie_detail_screen.dart';
import '../movie/category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  int _bannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              title: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: 'Dizzy', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
                    TextSpan(text: '.tv', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
                IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
              ],
            ),
            SliverToBoxAdapter(child: _buildBannerSlider()),
            SliverToBoxAdapter(child: _buildContinueWatching()),
            SliverToBoxAdapter(child: _buildCategories()),
            SliverToBoxAdapter(child: _buildMovieSection('🔥 Trend kinolar', _firestoreService.trendingMovies())),
            SliverToBoxAdapter(child: _buildMovieSection('🆕 Yangi kinolar', _firestoreService.newMovies())),
            SliverToBoxAdapter(child: _buildMovieSection('⭐ Mashhur kinolar', _firestoreService.popularMovies())),
            SliverToBoxAdapter(child: _buildMovieSection('🎬 Tavsiya etilgan', _firestoreService.recommendedMovies())),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSlider() {
    return StreamBuilder<List<MovieModel>>(
      stream: _firestoreService.bannerMovies(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Text('Bannerlar yo\'q', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        final banners = snap.data!;
        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: banners.length,
              itemBuilder: (context, index, realIdx) {
                final movie = banners[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                  ),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: movie.bannerUrl.isNotEmpty ? movie.bannerUrl : movie.posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(color: AppColors.surface),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        right: 16,
                        child: Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                );
              },
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.92,
                autoPlay: true,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) => setState(() => _bannerIndex = index),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSmoothIndicator(
              activeIndex: _bannerIndex,
              count: banners.length,
              effect: const WormEffect(dotColor: AppColors.surfaceLight, activeDotColor: AppColors.primary, dotHeight: 6, dotWidth: 6),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueWatching() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return FutureBuilder<List<MovieModel>>(
      future: _firestoreService.continueWatchingMovies(uid),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final movies = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: '👀 Davom ettirish'),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => MovieCard(
                  movie: movies[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movies[i])),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '📂 Kategoriyalar'),
        SizedBox(
          height: 40,
          child: StreamBuilder<List<GenreModel>>(
            stream: _firestoreService.genres(),
            builder: (context, snap) {
              final genres = snap.data ?? [];
              if (genres.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final g = genres[i];
                  return ActionChip(
                    label: Text(g.name),
                    backgroundColor: AppColors.surface,
                    labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CategoryScreen(genreName: g.name)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMovieSection(String title, Stream<List<MovieModel>> stream) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title, onSeeAll: () {}),
        SizedBox(
          height: 210,
          child: StreamBuilder<List<MovieModel>>(
            stream: stream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final movies = snap.data!;
              if (movies.isEmpty) {
                return const Center(child: Text('Hozircha kino yo\'q', style: TextStyle(color: AppColors.textSecondary)));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => MovieCard(
                movie: movies[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movies[i])),
                ),
              ),
              );
            },
          ),
        ),
      ],
    );
  }
}
