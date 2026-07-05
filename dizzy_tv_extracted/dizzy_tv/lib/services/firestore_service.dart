import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movie_model.dart';

/// Firestore bilan barcha kino / janr / saqlangan / tarix ishlarini bajaradi
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _movies =>
      _db.collection('movies');
  CollectionReference<Map<String, dynamic>> get _genres =>
      _db.collection('genres');
  CollectionReference<Map<String, dynamic>> get _banners =>
      _db.collection('banners');

  // ---------- BOSH SAHIFA UCHUN OQIMLAR ----------

  Stream<List<MovieModel>> bannerMovies() {
    return _movies
        .where('isActive', isEqualTo: true)
        .where('isBanner', isEqualTo: true)
        .limit(8)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<MovieModel>> trendingMovies() {
    return _movies
        .where('isActive', isEqualTo: true)
        .where('isTrending', isEqualTo: true)
        .limit(15)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<MovieModel>> newMovies() {
    return _movies
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(15)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<MovieModel>> popularMovies() {
    return _movies
        .where('isActive', isEqualTo: true)
        .orderBy('viewsCount', descending: true)
        .limit(15)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<MovieModel>> recommendedMovies() {
    return _movies
        .where('isActive', isEqualTo: true)
        .where('isRecommended', isEqualTo: true)
        .limit(15)
        .snapshots()
        .map(_mapSnapshot);
  }

  Stream<List<GenreModel>> genres() {
    return _genres.orderBy('order').snapshots().map(
          (snap) => snap.docs
              .map((d) => GenreModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ---------- QIDIRUV / FILTR ----------

  Future<List<MovieModel>> searchMovies({
    String? keyword,
    String? genre,
    int? year,
    String? country,
    double? minRating,
  }) async {
    Query<Map<String, dynamic>> query =
        _movies.where('isActive', isEqualTo: true);
    if (genre != null) query = query.where('genres', arrayContains: genre);
    if (year != null) query = query.where('year', isEqualTo: year);
    if (country != null) query = query.where('country', isEqualTo: country);

    final snap = await query.limit(50).get();
    var results = _mapSnapshot(snap);

    if (keyword != null && keyword.trim().isNotEmpty) {
      final kw = keyword.toLowerCase();
      results =
          results.where((m) => m.title.toLowerCase().contains(kw)).toList();
    }
    if (minRating != null) {
      results = results.where((m) => m.rating >= minRating).toList();
    }
    return results;
  }

  // ---------- SAQLANGANLAR / TARIX ----------

  Future<void> toggleSaved(String uid, String movieId, bool isSaved) async {
    final userRef = _db.collection('users').doc(uid);
    await userRef.update({
      'savedMovieIds': isSaved
          ? FieldValue.arrayRemove([movieId])
          : FieldValue.arrayUnion([movieId]),
    });
  }

  Future<void> addToHistory(String uid, String movieId) async {
    await saveWatchProgress(
        uid: uid, movieId: movieId, positionSeconds: 0, durationSeconds: 0);
  }

  /// Video ko'rish jarayonini saqlaydi (resume/"Davom ettirish" uchun).
  Future<void> saveWatchProgress({
    required String uid,
    required String movieId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('watchHistory')
        .doc(movieId)
        .set({
      'movieId': movieId,
      'position': positionSeconds,
      'duration': durationSeconds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getWatchProgress(
      String uid, String movieId) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('watchHistory')
        .doc(movieId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  /// To'liq ko'rish tarixi
  Stream<List<Map<String, dynamic>>> watchHistoryStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('watchHistory')
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// "Davom ettirish" bo'limi uchun: tugatilmagan kinolar
  Future<List<MovieModel>> continueWatchingMovies(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('watchHistory')
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .get();

    final unfinished = snap.docs.where((d) {
      final data = d.data();
      final pos = (data['position'] ?? 0) as int;
      final dur = (data['duration'] ?? 0) as int;
      return dur > 0 && pos > 5 && pos < dur * 0.95;
    }).toList();

    final ids = unfinished.map((d) => d.id).toList();
    final movies = await getMoviesByIds(ids);
    movies.sort(
        (a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return movies;
  }

  Future<void> incrementViews(String movieId) async {
    await _movies
        .doc(movieId)
        .update({'viewsCount': FieldValue.increment(1)});
  }

  Future<List<MovieModel>> getMoviesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap =
        await _movies.where(FieldPath.documentId, whereIn: ids).get();
    return _mapSnapshot(snap);
  }

  // ---------- ADMIN CRUD ----------

  Future<void> addMovie(MovieModel movie) => _movies.add(movie.toMap());
  Future<void> updateMovie(String id, Map<String, dynamic> data) =>
      _movies.doc(id).update(data);
  Future<void> deleteMovie(String id) => _movies.doc(id).delete();

  Future<void> addGenre(GenreModel genre) => _genres.add(genre.toMap());
  Future<void> updateGenre(String id, Map<String, dynamic> data) =>
      _genres.doc(id).update(data);
  Future<void> deleteGenre(String id) => _genres.doc(id).delete();

  // ---------- BANNERLAR (admin) ----------

  Stream<List<Map<String, dynamic>>> bannersStream() {
    return _banners.orderBy('order').snapshots().map(
          (snap) => snap.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList(),
        );
  }

  Future<void> addBanner(Map<String, dynamic> data) => _banners.add(data);
  Future<void> updateBanner(String id, Map<String, dynamic> data) =>
      _banners.doc(id).update(data);
  Future<void> deleteBanner(String id) => _banners.doc(id).delete();

  // ---------- ADMIN: barcha kinolarni ko'rish ----------
  Stream<List<MovieModel>> allMoviesAdmin() {
    return _movies
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  List<MovieModel> _mapSnapshot(
      QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => MovieModel.fromMap(d.id, d.data()))
        .toList();
  }
}
