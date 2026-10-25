import 'package:flutter/foundation.dart';

import '../core/firebase_status.dart';
import '../models/game.dart';
import '../services/game_repository.dart';

class GameViewModel extends ChangeNotifier {
  GameViewModel({GameRepository? repository, this._loadPopularGames = true})
    : _repository = repository ?? GameRepository();

  final GameRepository _repository;
  final bool _loadPopularGames;

  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _hasError = false;
  String? _errorMessage;

  List<Game> _games = [];
  List<Game> _mostDownloadedGames = [];

  List<String> _categories = ['All'];
  int _loadGeneration = 0;

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }

  bool get isLoading => _isLoading && !_hasLoaded;

  bool get hasError => _hasError && !_hasLoaded;

  String? get errorMessage => _errorMessage;

  List<Game> get games => List.unmodifiable(_games);

  List<Game> get mostDownloadedGames => List.unmodifiable(_mostDownloadedGames);

  List<String> get categories => List.unmodifiable(_categories);

  Future<void> loadGames({bool forceRefresh = false}) async {
    final int generation = ++_loadGeneration;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;

    notifyListeners();

    try {
      final List<Object> catalogResults = await Future.wait<Object>([
        _repository.fetchGames(forceRefresh: forceRefresh),
        _repository.fetchCategories(forceRefresh: forceRefresh),
      ]);
      if (generation != _loadGeneration) return;

      final List<Game> games = catalogResults[0] as List<Game>;
      final List<String> categories = catalogResults[1] as List<String>;

      _games = games;
      _categories = [
        'All',
        ...categories.where((category) => category != 'All'),
      ];

      _hasLoaded = true;
      _hasError = false;
      _isLoading = false;
      notifyListeners();

      if (_loadPopularGames) {
        await _loadMostDownloadedGames(games, generation);
      }
    } catch (error) {
      if (generation == _loadGeneration) {
        if (!_hasLoaded) {
          _hasError = true;
          _errorMessage =
              FirebaseStatus.initializationError ?? error.toString();
        }
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadMostDownloadedGames(
    List<Game> games,
    int generation,
  ) async {
    try {
      final Map<String, int> downloadCounts = await _repository
          .fetchDownloadCounts(games.map((game) => game.id).toList());
      if (generation != _loadGeneration) return;

      _mostDownloadedGames =
          games.where((game) {
            return (downloadCounts[game.id] ?? 0) > 0;
          }).toList()..sort((first, second) {
            return (downloadCounts[second.id] ?? 0).compareTo(
              downloadCounts[first.id] ?? 0,
            );
          });
      notifyListeners();
    } catch (_) {}
  }

  List<Game> getGamesByCategory(String category) {
    if (category == 'All') {
      return List<Game>.from(_games);
    }

    return _games.where((game) => game.category == category).toList();
  }
}
