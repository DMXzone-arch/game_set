import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game.dart';

class WishlistService {
  WishlistService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  final Map<String, List<Game>> _gamesCache = {};
  final Map<String, DateTime> _gamesCacheTime = {};

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
    final String? uid = _registeredUser?.uid;
    if (uid != null) {
      _gamesCache.remove(uid);
      _gamesCacheTime.remove(uid);
    }
    final DocumentReference<Map<String, dynamic>> entry = wishlist.doc(game.id);
    if (saved) {
      await entry.set({
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await entry.delete();
    }
  }

  /// Loads saved games newest-first and caches the result for this session.
  Future<List<Game>> fetchGames() async {
    final CollectionReference<Map<String, dynamic>>? wishlist = _wishlist;
    if (wishlist == null) throw const WishlistSignInRequiredException();
    final String uid = _registeredUser!.uid;
    final List<Game>? cachedGames = _gamesCache[uid];
    final DateTime? cachedAt = _gamesCacheTime[uid];
    if (cachedGames != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(minutes: 1)) {
      return cachedGames;
    }

    final QuerySnapshot<Map<String, dynamic>> entries = await wishlist.get();

    final List<Game?> loadedGames = await Future.wait(
      entries.docs.map((entry) => _loadPublishedGame(wishlist, entry.id)),
    );
    final List<Game> games = loadedGames.whereType<Game>().toList();

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

    _gamesCache[uid] = games;
    _gamesCacheTime[uid] = DateTime.now();
    return games;
  }

  Future<Game?> _loadPublishedGame(
    CollectionReference<Map<String, dynamic>> wishlist,
    String gameId,
  ) async {
    try {
      final DocumentReference<Map<String, dynamic>> gameReference = _firestore
          .collection('games')
          .doc(gameId);
      final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
          await Future.wait([
            gameReference.get(),
            _firestore.collection('game_images').doc(gameId).get(),
          ]);
      final DocumentSnapshot<Map<String, dynamic>> gameSnapshot = snapshots[0];
      final Map<String, dynamic>? data = gameSnapshot.data();
      if (!gameSnapshot.exists ||
          data == null ||
          data['isPublished'] == false) {
        try {
          await wishlist.doc(gameId).delete();
        } catch (_) {
          // Keep the rest of the wishlist load working if pruning fails.
        }
        return null;
      }
      return Game.fromFirestore(
        id: gameSnapshot.id,
        data: data,
        images: snapshots[1].data() ?? const {},
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
