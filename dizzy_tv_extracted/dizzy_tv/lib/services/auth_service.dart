import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Barcha autentifikatsiya (oddiy foydalanuvchi + admin) shu servisda.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Email + parol bilan ro'yxatdan o'tish (oddiy foydalanuvchi)
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(uid: cred.user!.uid, email: email, name: name);
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  /// Email + parol bilan kirish
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUserModel(cred.user!.uid);
  }

  /// Google orqali kirish
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'cancelled', message: 'Bekor qilindi');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    final docRef = _firestore.collection('users').doc(userCred.user!.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUser = UserModel(
        uid: userCred.user!.uid,
        email: userCred.user!.email ?? '',
        name: userCred.user!.displayName ?? '',
        photoUrl: userCred.user!.photoURL ?? '',
      );
      await docRef.set(newUser.toMap());
      return newUser;
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  /// ADMIN LOGIN — oddiy foydalanuvchi bilan bir xil Firebase Auth,
  /// lekin kirishdan so'ng Firestore'dagi role="admin" tekshiriladi.
  /// Agar admin bo'lmasa, tizimdan chiqariladi va xatolik qaytariladi.
  Future<UserModel> adminLogin({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final userModel = await _fetchUserModel(cred.user!.uid);
    if (!userModel.isAdmin) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'not-admin',
        message: 'Bu hisobda admin huquqi yo\'q',
      );
    }
    return userModel;
  }

  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'no-profile',
        message: 'Foydalanuvchi profili topilmadi',
      );
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
