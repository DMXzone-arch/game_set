import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  AdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Future<void> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = credential.user;
    if (user == null) {
      await _auth.signOut();
      throw const AdminAccessDeniedException();
    }
    try {
      if (!await isAdmin(user.uid)) {
        throw const AdminAccessDeniedException();
      }
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<bool> isAdmin(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> userDocument = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    return userDocument.data()?['role'] == 'admin';
  }

  Future<void> signOut() => _auth.signOut();
}

class AdminAccessDeniedException implements Exception {
  const AdminAccessDeniedException();

  @override
  String toString() => 'This account does not have admin access.';
}
