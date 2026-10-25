import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firestore rejects display names longer than this on write.
const int kMaxDisplayNameLength = 40;

class UserProfileService {
  UserProfileService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static Future<void>? _googleSignInInitialization;
  final Map<String, Map<String, dynamic>?> _profileCache = {};
  final Map<String, DateTime> _profileCacheTime = {};

  User? get currentUser => _auth.currentUser;
  Stream<User?> authChanges() => _auth.authStateChanges();

  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
    required int avatarId,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    final User user = credential.user!;
    try {
      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': name.trim(),
        'email': user.email,
        'avatarId': avatarId.clamp(0, 4).toInt(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = credential.user;
    if (user != null) {
      try {
        await _ensureProfile(user);
      } catch (_) {
        await _auth.signOut();
        rethrow;
      }
    }
    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    late final UserCredential credential;
    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      try {
        _googleSignInInitialization ??= GoogleSignIn.instance.initialize();
        await _googleSignInInitialization;
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance
            .authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw StateError(
            'Google did not return an ID token. Check the OAuth client setup.',
          );
        }
        credential = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      } on GoogleSignInException catch (error) {
        if (error.code == GoogleSignInExceptionCode.canceled) return null;
        rethrow;
      }
    }
    if (credential.user != null) {
      try {
        await _ensureProfile(credential.user!);
      } catch (_) {
        await _auth.signOut();
        rethrow;
      }
    }
    return credential;
  }

  Future<void> _ensureProfile(User user) async {
    final DocumentReference<Map<String, dynamic>> profile = _firestore
        .collection('users')
        .doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await profile.get();
    if (snapshot.exists) return;

    final String email = user.email ?? '';
    await profile.set({
      'displayName': user.displayName ?? email.split('@').first,
      'email': email,
      'avatarId': Random.secure().nextInt(5),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> updateProfile({
    required String displayName,
    required int avatarId,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const ProfileUpdateRequiresSignInException();
    }

    final String trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const InvalidDisplayNameException('Enter a display name.');
    }
    if (trimmedName.length > kMaxDisplayNameLength) {
      throw const InvalidDisplayNameException(
        'Display names can be at most 40 characters.',
      );
    }

    // Firestore first: it is the source of truth for the profile screen. If the
    // Firebase Auth rename then fails, the catalog is still consistent and only
    // the auth-side display name lags behind, which is not shown to the user.
    final DocumentReference<Map<String, dynamic>> profile = _firestore
        .collection('users')
        .doc(user.uid);

    // A profile document may not exist yet (for example an account created
    // before the profile write landed). `set` with merge then performs a
    // *create*, and the rules only allow a create that carries every required
    // field. Writing the full document keeps both cases working.
    final DocumentSnapshot<Map<String, dynamic>> probe = await profile.get();
    final bool exists = probe.exists;
    if (exists) {
      await profile.set({
        'displayName': trimmedName,
        'avatarId': avatarId.clamp(0, 4).toInt(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await profile.set({
        'displayName': trimmedName,
        'email': user.email,
        'avatarId': avatarId.clamp(0, 4).toInt(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // The write may create a document with server timestamps and required
    // account fields; invalidate the partial cached view so the next read
    // returns the complete Firestore document.
    _profileCache.remove(user.uid);
    _profileCacheTime.remove(user.uid);

    try {
      await user.updateDisplayName(trimmedName);
    } catch (_) {
      // The profile itself saved successfully; only the auth mirror is stale.
    }
  }

  /// The authoritative email for the signed-in account.
  ///
  /// Email is owned by Firebase Auth and is immutable in this app's data model:
  /// `firestore.rules` does not allow `email` in a profile update. Reading it
  /// from Auth keeps the UI correct even if a profile document is stale.
  Future<String?> fetchAccountEmail() async {
    final User? user = _auth.currentUser;
    return user?.email;
  }

  Future<bool> isEmailVerified() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  Future<void> sendEmailVerification() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const ProfileUpdateRequiresSignInException();
    }
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final DateTime? cachedAt = _profileCacheTime[uid];
    if (_profileCache.containsKey(uid) &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(minutes: 1)) {
      return _profileCache[uid];
    }
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    final Map<String, dynamic>? profile = snapshot.data();
    _profileCache[uid] = profile;
    _profileCacheTime[uid] = DateTime.now();
    return profile;
  }

  Future<void> signOut() => _auth.signOut();
}

class ProfileUpdateRequiresSignInException implements Exception {
  const ProfileUpdateRequiresSignInException();

  @override
  String toString() => 'No signed-in account can save this profile.';
}

class InvalidDisplayNameException implements Exception {
  const InvalidDisplayNameException(this.message);

  final String message;

  @override
  String toString() => message;
}
