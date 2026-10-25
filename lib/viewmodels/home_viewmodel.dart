import 'package:flutter/foundation.dart';

import '../models/game.dart';
import 'game_viewmodel.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    GameViewModel? gameViewModel,
    bool loadPopularGames = true,
  }) : _gameViewModel =
           gameViewModel ??
           GameViewModel(loadPopularGames: loadPopularGames) {
    _gameViewModel.addListener(_onGameViewModelChanged);
  }

  final GameViewModel _gameViewModel;

  String selectedCategory = 'All';
  String submittedSearchQuery = '';
  bool _disposed = false;

  bool get isLoading => _gameViewModel.isLoading;

  bool get hasError => _gameViewModel.hasError;

  String? get errorMessage => _gameViewModel.errorMessage;

  List<String> get categories => _gameViewModel.categories;

  List<Game> get filteredGames {
    return _filterGames(_gameViewModel.games);
  }

  List<Game> get filteredMostDownloadedGames {
    return _filterGames(_gameViewModel.mostDownloadedGames);
  }

  List<Game> getGamesByCategory(String category) =>
      _gameViewModel.getGamesByCategory(category);

  List<Game> _filterGames(List<Game> games) {
    final String query = submittedSearchQuery.toLowerCase().trim();
    final List<Game> categoryGames = games
        .where(
          (game) =>
              (selectedCategory == 'All' ||
                  game.category == selectedCategory),
        )
        .toList();

    if (query.isEmpty) return categoryGames;

    final List<Game> exactMatches = categoryGames
        .where((game) => game.name.toLowerCase().contains(query))
        .toList();
    if (exactMatches.isNotEmpty) return exactMatches;

    final List<({Game game, double score})> relatedMatches = [];
    for (final Game game in categoryGames) {
      final double score = _fuzzyNameMatchScore(game.name, query);
      if (score >= 0.58) relatedMatches.add((game: game, score: score));
    }
    relatedMatches.sort((first, second) => second.score.compareTo(first.score));
    return relatedMatches.map((match) => match.game).toList();
  }

  double _fuzzyNameMatchScore(String name, String query) {
    final List<String> queryWords = RegExp(
      r'[a-z0-9]+',
    ).allMatches(query).map((match) => match[0]!).toList();
    final List<String> nameWords = RegExp(
      r'[a-z0-9]+',
    ).allMatches(name.toLowerCase()).map((match) => match[0]!).toList();
    if (queryWords.isEmpty || nameWords.isEmpty) return 0;

    double totalScore = 0;
    for (final String queryWord in queryWords) {
      double bestScore = 0;
      for (final String nameWord in nameWords) {
        if (nameWord == queryWord || nameWord.contains(queryWord)) {
          bestScore = 1;
          break;
        }
        if (queryWord.length < 3) continue;

        final int distance = _editDistance(queryWord, nameWord);
        final int wordLength = queryWord.length > nameWord.length
            ? queryWord.length
            : nameWord.length;
        final double score = 1 - distance / wordLength;
        if (score > bestScore) bestScore = score;
      }
      if (bestScore < 0.58) return 0;
      totalScore += bestScore;
    }
    return totalScore / queryWords.length;
  }

  int _editDistance(String first, String second) {
    List<int> previous = List<int>.generate(second.length + 1, (index) => index);
    for (int row = 1; row <= first.length; row++) {
      final List<int> current = List<int>.filled(second.length + 1, 0);
      current[0] = row;
      for (int column = 1; column <= second.length; column++) {
        final int substitutionCost =
            first.codeUnitAt(row - 1) == second.codeUnitAt(column - 1) ? 0 : 1;
        final int insert = current[column - 1] + 1;
        final int delete = previous[column] + 1;
        final int substitute = previous[column - 1] + substitutionCost;
        current[column] = insert < delete
            ? (insert < substitute ? insert : substitute)
            : (delete < substitute ? delete : substitute);
      }
      previous = current;
    }
    return previous[second.length];
  }

  Future<void> loadGames({bool forceRefresh = false}) async {
    await _gameViewModel.loadGames(forceRefresh: forceRefresh);
    if (!_disposed) notifyListeners();
  }

  void submitSearch(String query) {
    submittedSearchQuery = query.trim();
    notifyListeners();
  }

  void clearSearch() {
    submittedSearchQuery = '';
    notifyListeners();
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void _onGameViewModelChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _gameViewModel.removeListener(_onGameViewModelChanged);

    _gameViewModel.dispose();

    super.dispose();
  }
}
