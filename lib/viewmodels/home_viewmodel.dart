import 'package:flutter/foundation.dart';

import '../models/game.dart';
import 'game_viewmodel.dart';

class HomeViewModel extends ChangeNotifier {
  final GameViewModel _gameViewModel = GameViewModel();

  String selectedCategory = 'All';
  String submittedSearchQuery = '';

  HomeViewModel() {
    _gameViewModel.addListener(_onGameViewModelChanged);
  }

  bool get isLoading => _gameViewModel.isLoading;

  bool get hasError => _gameViewModel.hasError;

  List<String> get categories => _gameViewModel.categories;

  List<Game> get filteredGames {
    final String query =
        submittedSearchQuery.toLowerCase().trim();

    return _gameViewModel
        .getGamesByCategory(selectedCategory)
        .where(
          (game) =>
              game.name.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> loadGames() async {
    await _gameViewModel.loadGames();
    notifyListeners();
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
    notifyListeners();
  }

  @override
  void dispose() {
    _gameViewModel.removeListener(
      _onGameViewModelChanged,
    );

    _gameViewModel.dispose();

    super.dispose();
  }
}