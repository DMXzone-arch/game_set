import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game.dart';

class GameRepository {
  GameRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _database => firestore ?? FirebaseFirestore.instance;

  Future<List<Game>> fetchGames() => _fetchGames(includeUnpublished: false);

  Future<List<Game>> fetch7Games() => _fetchGames(includeUnpublished: true);

  Future<List<Game>> _fetchGames({required bool includeUnpublished}) async {
    Query<Map<String, dynamic>> gameQuery = _database.collection('games');
    if (!includeUnpublished) {
      gameQuery = gameQuery.where('isPublished', isEqualTo: true);
    }
    final QuerySnapshot<Map<String, dynamic>> gameSnapshot = await gameQuery
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> imageSnapshots =
        await Future.wait(
          gameSnapshot.docs.map(
            (game) => _database.collection('game_images').doc(game.id).get(),
          ),
        );

    final List<Game> games = [];
    for (var index = 0; index < gameSnapshot.docs.length; index++) {
      final QueryDocumentSnapshot<Map<String, dynamic>> gameDocument =
          gameSnapshot.docs[index];
      final Map<String, dynamic> gameData = gameDocument.data();

      games.add(
        Game.fromFirestore(
          id: gameDocument.id,
          data: gameData,
          images: imageSnapshots[index].data() ?? const {},
        ),
      );
    }

    return games;
  }

  Future<Map<String, int>> fetchDownloadCounts(List<String> gameIds) async {
    if (gameIds.isEmpty) return const {};

    final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait(
          gameIds.map(
            (gameId) => _database.collection('downloads').doc(gameId).get(),
          ),
        );
    final Map<String, int> counts = {};
    for (var index = 0; index < gameIds.length; index++) {
      final Object? count = snapshots[index].data()?['count'];
      if (count is num && count > 0) counts[gameIds[index]] = count.toInt();
    }
    return counts;
  }

  Future<List<String>> fetchCategories() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _database
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .get();

    final List<String> categories =
        snapshot.docs
            .where((document) => document.data()['isActive'] != false)
            .map((document) => document.data()['name'])
            .whereType<String>()
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return categories;
  }

  Future<void> incrementDownloadCount(String gameId) {
    return _database.collection('downloads').doc(gameId).set({
      'count': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
