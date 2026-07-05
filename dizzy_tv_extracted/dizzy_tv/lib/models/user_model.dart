/// Firestore "users" kolleksiyasidagi foydalanuvchi hujjati.
/// "role" maydoni orqali oddiy foydalanuvchi va admin farqlanadi.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final String role; // "user" yoki "admin"
  final List<String> savedMovieIds;
  final List<String> historyMovieIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl = '',
    this.role = 'user',
    this.savedMovieIds = const [],
    this.historyMovieIds = const [],
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'user',
      savedMovieIds: List<String>.from(map['savedMovieIds'] ?? []),
      historyMovieIds: List<String>.from(map['historyMovieIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'savedMovieIds': savedMovieIds,
      'historyMovieIds': historyMovieIds,
    };
  }
}
