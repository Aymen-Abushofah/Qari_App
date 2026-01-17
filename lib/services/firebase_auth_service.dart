import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FirebaseAuthService: Handles all user authentication flows.
///
/// Key Security Features:
/// 1. Login Validation: Checks Firestore for the existence of a user document
///    to prevent deactivated/deleted users from logging in.
/// 2. Session Management: Provides streams for the current user's auth state.
/// 3. Error Handling: Normalizes Firebase exceptions into user-friendly Arabic messages.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Singleton Pattern ---
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  /// Returns the currently authenticated Firebase User (if any).
  User? get currentUser => _auth.currentUser;

  /// Stream that emits events whenever the user's auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Attempts to authenticate a user.
  ///
  /// Returns: null if successful, or an error message (Arabic) if it fails.
  /// IMPORTANT: Even if password is correct, if the 'users' document is missing,
  /// the login is rejected and the user is signed out.
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- Security Check ---
      // Real-time Verify user document exists in Firestore.
      // If an admin deleted the user, doc.exists will be FALSE.
      if (credential.user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (!doc.exists) {
          await _auth.signOut();
          return 'تم تعطيل هذا الحساب. يرجى الاتصال بالمسؤول.';
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      // Map common errors to Arabic
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Creates a new Firebase Auth account.
  ///
  /// Note: User profile data is handled separately in [FirestoreService].
  Future<String?> signup({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Ends the current user session.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Deletes the currently authenticated user's account.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
