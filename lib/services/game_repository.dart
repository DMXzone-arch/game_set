import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game.dart';

class GameRepository {
  GameRepository({this.firestore});

  static const Duration _catalogCacheDuration = Duration(seconds: 60);
  static List<Game>? _catalogCache;
  static DateTime? _catalogCacheTime;
  static List<String>? _categoryCache;
  static DateTime? _categoryCacheTime;
  static final Map<String, Game> _gameDetailsCache = {};
  static final Map<String, DateTime> _gameDetailsCacheTime = {};

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _database => firestore ?? FirebaseFirestore.instance;

  Future<List<Game>> fetchGames({bool forceRefresh = false}) async {
    final DateTime now = DateTime.now();
    final List<Game>? cached = _catalogCache;
    final DateTime? cachedAt = _catalogCacheTime;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _catalogCacheDuration) {
      return cached;
    }

    final Query<Map<String, dynamic>> gameQuery = _database
        .collection('games')
        .where('isPublished', isEqualTo: true);
    final QuerySnapshot<Map<String, dynamic>> gameSnapshot = await gameQuery
        .get();

    final List<Game> games = gameSnapshot.docs
        .map(
          (document) => Game.fromCatalogFirestore(
            id: document.id,
            data: document.data(),
          ),
        )
        .toList();
    _catalogCache = games;
    _catalogCacheTime = now;
    return games;
  }

  Future<String?> fetchGameIcon(String gameId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _database
        .collection('game_images')
        .doc(gameId)
        .get();
    final Object? icon = snapshot.data()?['iconUrl'];
    return icon is String && icon.trim().isNotEmpty ? icon.trim() : null;
  }

  Future<Game?> fetchGameDetails(String gameId) async {
    final Game? cachedGame = _gameDetailsCache[gameId];
    final DateTime? cachedAt = _gameDetailsCacheTime[gameId];
    if (cachedGame != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _catalogCacheDuration) {
      return cachedGame;
    }

    final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait([
          _database.collection('games').doc(gameId).get(
            const GetOptions(source: Source.server),
          ),
          _database.collection('game_images').doc(gameId).get(
            const GetOptions(source: Source.server),
          ),
        ]);
    final DocumentSnapshot<Map<String, dynamic>> gameSnapshot = snapshots[0];
    if (!gameSnapshot.exists || gameSnapshot.data()?['isPublished'] == false) {
      return null;
    }
    final Game game = Game.fromFirestore(
      id: gameSnapshot.id,
      data: gameSnapshot.data() ?? const {},
      images: snapshots[1].data() ?? const {},
    );
    _gameDetailsCache[gameId] = game;
    _gameDetailsCacheTime[gameId] = DateTime.now();
    return game;
  }

  Future<Game?> fetchCachedGameDetails(String gameId) async {
    final Game? cachedGame = _gameDetailsCache[gameId];
    if (cachedGame != null) return cachedGame;

    late final DocumentSnapshot<Map<String, dynamic>> gameSnapshot;
    try {
      gameSnapshot = await _database
          .collection('games')
          .doc(gameId)
          .get(const GetOptions(source: Source.cache));
    } catch (_) {
      return null;
    }
    if (!gameSnapshot.exists || gameSnapshot.data()?['isPublished'] == false) {
      return null;
    }

    DocumentSnapshot<Map<String, dynamic>>? imagesSnapshot;
    try {
      imagesSnapshot = await _database
          .collection('game_images')
          .doc(gameId)
          .get(const GetOptions(source: Source.cache));
    } catch (_) {
      // The game document can be cached even when its separate image document is not.
    }

    final Game game = Game.fromFirestore(
      id: gameSnapshot.id,
      data: gameSnapshot.data() ?? const {},
      images: imagesSnapshot?.data() ?? const {},
    );
    _gameDetailsCache[gameId] = game;
    return game;
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

  Future<List<String>> fetchCategories({bool forceRefresh = false}) async {
    final DateTime now = DateTime.now();
    final List<String>? cached = _categoryCache;
    final DateTime? cachedAt = _categoryCacheTime;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _catalogCacheDuration) {
      return cached;
    }

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

    _categoryCache = categories;
    _categoryCacheTime = now;
    return categories;
  }

  Future<void> incrementDownloadCount(String gameId) {
    return _database.collection('downloads').doc(gameId).set({
      'count': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
