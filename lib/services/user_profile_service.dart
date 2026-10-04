import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  UserProfileService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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
        final DocumentReference<Map<String, dynamic>> profile = _firestore
            .collection('users')
            .doc(user.uid);
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await profile
            .get();
        if (!snapshot.exists) {
          final String emailAddress = user.email ?? email.trim();
          await profile.set({
            'displayName': user.displayName ?? emailAddress.split('@').first,
            'email': emailAddress,
            'avatarId': Random.secure().nextInt(5),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {
        await _auth.signOut();
        rethrow;
      }
    }
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> updateProfile({
    required String displayName,
    required int avatarId,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName.trim());
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': displayName.trim(),
      'avatarId': avatarId.clamp(0, 4).toInt(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    return snapshot.data();
  }

  Future<void> signOut() => _auth.signOut();
}

class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarId,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final int avatarId;
  final String role;
  final DateTime? createdAt;

  factory AdminUserRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final Object? timestamp = data['createdAt'];
    return AdminUserRecord(
      id: id,
      email: data['email'] is String ? data['email'] as String : '',
      displayName: data['displayName'] is String
          ? data['displayName'] as String
          : '',
      avatarId: data['avatarId'] is num
          ? (data['avatarId'] as num).toInt().clamp(0, 4).toInt()
          : 0,
      role: data['role'] is String ? data['role'] as String : 'user',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}

Future<List<AdminUserRecord>> fetchAdminUserRecords({
  FirebaseFirestore? firestore,
}) async {
  final QuerySnapshot<Map<String, dynamic>> snapshot =
      await (firestore ?? FirebaseFirestore.instance).collection('users').get();
  final List<AdminUserRecord> users = snapshot.docs
      .map(
        (document) =>
            AdminUserRecord.fromFirestore(document.id, document.data()),
      )
      .toList();
  users.sort((first, second) {
    final DateTime firstDate =
        first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime secondDate =
        second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return secondDate.compareTo(firstDate);
  });
  return users;
}
