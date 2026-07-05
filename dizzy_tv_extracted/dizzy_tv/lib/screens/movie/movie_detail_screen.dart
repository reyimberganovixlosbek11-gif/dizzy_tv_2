import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/movie_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class MovieDetailScreen extends StatefulWidget {
  final MovieModel movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _firestoreService = FirestoreService();
  bool _isSaved = false;
  bool _playing = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoLoading = false;
  int _resumePositionSeconds = 0;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final progress = await _firestoreService.getWatchProgress(uid, widget.movie.id);
    if (progress != null && mounted) {
      setState(() => _resumePositionSeconds = (progress['position'] ?? 0) as int);
    }
  }

  @override
  void dispose() {
    _saveCurrentProgress();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _saveCurrentProgress() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final controller = _videoController;
    if (uid == null || controller == null || !controller.value.isInitialized) return;
    _firestoreService.saveWatchProgress(
      uid: uid,
      movieId: widget.movie.id,
      positionSeconds: controller.value.position.inSeconds,
      durationSeconds: controller.value.duration.inSeconds,
    );
  }

  Future<void> _startPlayback() async {
    setState(() => _videoLoading = true);
    try {
      // Cloudflare R2 dagi video manzilidan to'g'ridan-to'g'ri oqim
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.movie.videoUrl));
      await _videoController!.initialize();
      if (_resumePositionSeconds > 5) {
        await _videoController!.seekTo(Duration(seconds: _resumePositionSeconds));
      }
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.surfaceLight,
          backgroundColor: AppColors.surface,
        ),
      );
      // Har safar pozitsiya o'zgarganda (~15 soniyada bir marta) progressni saqlaymiz —
      // shunda ilova yopilsa ham "Davom ettirish" ishlaydi.
      _videoController!.addListener(_onVideoTick);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.addToHistory(uid, widget.movie.id);
      }
      await _firestoreService.incrementViews(widget.movie.id);
      setState(() {
        _playing = true;
        _videoLoading = false;
      });
    } catch (e) {
      setState(() => _videoLoading = false);
      Fluttertoast.showToast(msg: 'Videoni yuklashda xatolik yuz berdi');
    }
  }

  void _onVideoTick() {
    final now = DateTime.now();
    if (now.difference(_lastProgressSave).inSeconds >= 15) {
      _lastProgressSave = now;
      _saveCurrentProgress();
    }
  }

  Future<void> _toggleSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.toggleSaved(uid, widget.movie.id, _isSaved);
    setState(() => _isSaved = !_isSaved);
    Fluttertoast.showToast(msg: _isSaved ? 'Saqlandi' : 'Saqlanganlardan olib tashlandi');
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    if (_playing && _chewieController != null) {
      // To'liq ekran video pleyer rejimi
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio == 0
                    ? 16 / 9
                    : _videoController!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movie.title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(movie.description, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 480,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: movie.posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: AppColors.surface),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _InfoChip(icon: Icons.calendar_today, label: '${movie.year}'),
                      _InfoChip(icon: Icons.timer, label: '${movie.durationMinutes} daq'),
                      _InfoChip(icon: Icons.star, label: movie.rating.toStringAsFixed(1), color: AppColors.gold),
                      _InfoChip(icon: Icons.remove_red_eye, label: '${movie.viewsCount}'),
                      _InfoChip(icon: Icons.hd, label: movie.quality),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: movie.genres
                        .map((g) => Chip(
                              label: Text(g, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                              backgroundColor: AppColors.surface,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  if (_resumePositionSeconds > 5 && !_videoLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Siz ${_formatTime(_resumePositionSeconds)} gacha ko\'rgansiz',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _videoLoading ? null : _startPlayback,
                          icon: _videoLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_videoLoading
                              ? 'Yuklanmoqda...'
                              : (_resumePositionSeconds > 5 ? 'DAVOM ETTIRISH' : 'KO\'RISH')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _toggleSave,
                        icon: Icon(
                          _isSaved ? Icons.favorite : Icons.favorite_border,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Tavsif', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(movie.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 24),
                  const Text('Sharhlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Hozircha sharhlar yo\'q. Birinchi bo\'lib fikr bildiring!',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}soat ${m}daq';
    return '${m}daq';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
