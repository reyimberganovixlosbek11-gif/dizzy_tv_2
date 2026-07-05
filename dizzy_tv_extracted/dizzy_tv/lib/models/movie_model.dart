import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore "movies" kolleksiyasidagi bitta kino hujjatini ifodalaydi
class MovieModel {
  final String id;
  final String title;
  final String description;
  final String posterUrl; // Firebase Storage'dagi poster
  final String bannerUrl; // Bosh sahifa banneri uchun (ixtiyoriy)
  final String videoUrl; // Cloudflare R2 dagi video manzili
  final int year;
  final List<String> genres; // Bir nechta janr
  final String country;
  final double rating; // 0 - 10
  final int durationMinutes;
  final String quality; // masalan: "HD", "4K", "FHD"
  final int viewsCount;
  final bool isActive;
  final bool isBanner; // Bosh sahifa sliderida ko'rsatilsinmi
  final bool isTrending;
  final bool isNew;
  final bool isPopular;
  final bool isRecommended;
  final DateTime createdAt;

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    this.bannerUrl = '',
    required this.videoUrl,
    required this.year,
    required this.genres,
    required this.country,
    required this.rating,
    required this.durationMinutes,
    required this.quality,
    this.viewsCount = 0,
    this.isActive = true,
    this.isBanner = false,
    this.isTrending = false,
    this.isNew = false,
    this.isPopular = false,
    this.isRecommended = false,
    required this.createdAt,
  });

  factory MovieModel.fromMap(String id, Map<String, dynamic> map) {
    return MovieModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      posterUrl: map['posterUrl'] ?? '',
      bannerUrl: map['bannerUrl'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      year: map['year'] ?? 0,
      genres: List<String>.from(map['genres'] ?? []),
      country: map['country'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      durationMinutes: map['durationMinutes'] ?? 0,
      quality: map['quality'] ?? 'HD',
      viewsCount: map['viewsCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      isBanner: map['isBanner'] ?? false,
      isTrending: map['isTrending'] ?? false,
      isNew: map['isNew'] ?? false,
      isPopular: map['isPopular'] ?? false,
      isRecommended: map['isRecommended'] ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'bannerUrl': bannerUrl,
      'videoUrl': videoUrl,
      'year': year,
      'genres': genres,
      'country': country,
      'rating': rating,
      'durationMinutes': durationMinutes,
      'quality': quality,
      'viewsCount': viewsCount,
      'isActive': isActive,
      'isBanner': isBanner,
      'isTrending': isTrending,
      'isNew': isNew,
      'isPopular': isPopular,
      'isRecommended': isRecommended,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Janr modeli (admin panelda boshqariladi)
class GenreModel {
  final String id;
  final String name;
  final int order;

  GenreModel({required this.id, required this.name, this.order = 0});

  factory GenreModel.fromMap(String id, Map<String, dynamic> map) {
    return GenreModel(id: id, name: map['name'] ?? '', order: map['order'] ?? 0);
  }

  Map<String, dynamic> toMap() => {'name': name, 'order': order};
}
