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
      await entry.set({
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await entry.delete();
    }
  }

  /// Loads the saved games newest-first and drops entries whose game is no
/// longer published.
///
/// Wishlist entries are pruned from Firestore when they can no longer resolve,
/// so an unpublished or deleted game does not leave a permanently broken entry
/// behind that silently reappears later.
Future<List<Game>> fetchGames() async {
    final CollectionReference<Map<String, dynamic>>? wishlist = _wishlist;
    if (wishlist == null) throw const WishlistSignInRequiredException();

    final QuerySnapshot<Map<String, dynamic>> entries = await wishlist.get();

    final List<Game?> loadedGames = await Future.wait(
      entries.docs.map((entry) => _loadPublishedGame(entry.id)),
    );
    final List<Game> games = loadedGames.whereType<Game>().toList();

    // Drop entries whose game is no longer published, so they cannot resurface.
    await Future.wait(
      entries.docs.map((entry) => _pruneIfMissing(wishlist, entry.id)),
    );

    // Newest saves first, matching the order the heart was tapped.
    final Map<String, DateTime?> addedAt = {};
    for (final entry in entries.docs) {
      final Object? stamp = entry.data()['addedAt'];
      addedAt[entry.id] = stamp is Timestamp ? stamp.toDate() : null;
    }
    games.sort((first, second) {
      final DateTime? a = addedAt[first.id];
      final DateTime? b = addedAt[second.id];
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return b.compareTo(a);
    });

    return games;
  }

  /// Removes a wishlist entry when its game is unpublished or deleted.
  Future<void> _pruneIfMissing(
    CollectionReference<Map<String, dynamic>> wishlist,
    String gameId,
  ) async {
    try {
      if (await _isGamePublished(gameId)) return;
      await wishlist.doc(gameId).delete();
    } catch (_) {
      // Never fail the whole load because a single stale entry failed to prune.
    }
  }

  Future<bool> _isGamePublished(String gameId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('games')
          .doc(gameId)
          .get();
      return snapshot.exists && snapshot.data()?['isPublished'] != false;
    } catch (_) {
      // On a network error, keep the entry rather than deleting real data.
      return true;
    }
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
