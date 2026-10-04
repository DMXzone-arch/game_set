import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game.dart';

class WishlistService {
  WishlistService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get _registeredUser {
    final User? user = _auth.currentUser;
    return user != null && !user.isAnonymous ? user : null;
  }

  CollectionReference<Map<String, dynamic>>? get _wishlist {
    final User? user = _registeredUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('wishlist');
  }

  Future<bool> isSaved(String gameId) async {
    final CollectionReference<Map<String, dynamic>>? wishlist = _wishlist;
    if (wishlist == null || gameId.isEmpty) return false;
    return (await wishlist.doc(gameId).get()).exists;
  }

  Future<void> setSaved(Game game, bool saved) async {
    final CollectionReference<Map<String, dynamic>>? wishlist = _wishlist;
    if (wishlist == null) throw const WishlistSignInRequiredException();
    if (game.id.isEmpty) return;
    final DocumentReference<Map<String, dynamic>> entry = wishlist.doc(game.id);
    if (saved) {
      await entry.set({'addedAt': FieldValue.serverTimestamp()});
    } else {
      await entry.delete();
    }
  }

  Future<List<Game>> fetchGames() async {
    final CollectionReference<Map<String, dynamic>>? wishlist = _wishlist;
    if (wishlist == null) throw const WishlistSignInRequiredException();

    final QuerySnapshot<Map<String, dynamic>> entries = await wishlist.get();
    final List<Game?> loadedGames = await Future.wait(
      entries.docs.map((entry) => _loadPublishedGame(entry.id)),
    );
    return loadedGames.whereType<Game>().toList();
  }

  Future<Game?> _loadPublishedGame(String gameId) async {
    try {
      final DocumentReference<Map<String, dynamic>> gameReference = _firestore
          .collection('games')
          .doc(gameId);
      final DocumentSnapshot<Map<String, dynamic>> gameSnapshot =
          await gameReference.get();
      final Map<String, dynamic>? data = gameSnapshot.data();
      if (!gameSnapshot.exists ||
          data == null ||
          data['isPublished'] == false) {
        return null;
      }
      final DocumentSnapshot<Map<String, dynamic>> images = await _firestore
          .collection('game_images')
          .doc(gameId)
          .get();
      return Game.fromFirestore(
        id: gameSnapshot.id,
        data: data,
        images: images.data() ?? const {},
      );
    } catch (_) {
      // A game may have been unpublished or removed after it was saved.
      return null;
    }
  }
}

class WishlistSignInRequiredException implements Exception {
  const WishlistSignInRequiredException();
}
