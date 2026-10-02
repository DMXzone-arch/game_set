import 'package:flutter/foundation.dart';

import '../core/firebase_status.dart';
import '../models/game.dart';
import '../services/game_repository.dart';

class GameViewModel extends ChangeNotifier {
  GameViewModel({GameRepository? repository})
    : _repository = repository ?? GameRepository();

  final GameRepository _repository;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<Game> _games = [];
  List<Game> _mostDownloadedGames = [];

  List<String> _categories = ['All'];

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  String? get errorMessage => _errorMessage;

  List<Game> get games => List.unmodifiable(_games);

  List<Game> get mostDownloadedGames => List.unmodifiable(_mostDownloadedGames);

  List<String> get categories => List.unmodifiable(_categories);

  Future<void> loadGames() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _mostDownloadedGames = [];

    notifyListeners();

    try {
      final List<Game> games = await _repository.fetchGames();
      final List<String> categories = await _repository.fetchCategories();
      Map<String, int> downloadCounts = {};
      try {
        downloadCounts = await _repository.fetchDownloadCounts(
          games.map((game) => game.id).toList(),
        );
      } catch (_) {}

      final List<Game> mostDownloadedGames =
          games.where((game) => (downloadCounts[game.id] ?? 0) > 0).toList()
            ..sort(
              (first, second) => (downloadCounts[second.id] ?? 0).compareTo(
                downloadCounts[first.id] ?? 0,
              ),
            );

      _games = games;
      _mostDownloadedGames = mostDownloadedGames;
      _categories = [
        'All',
        ...categories.where((category) => category != 'All'),
      ];

      _hasError = false;
    } catch (error) {
      _hasError = true;
      _errorMessage = FirebaseStatus.initializationError ?? error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Game> getGamesByCategory(String category) {
    if (category == 'All') {
      return List<Game>.from(_games);
    }

    return _games.where((game) => game.category == category).toList();
  }
}
