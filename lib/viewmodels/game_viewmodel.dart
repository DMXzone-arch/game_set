import 'package:flutter/foundation.dart';

import '../models/game.dart';

class GameViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;

  List<Game> _games = [];

  final List<String> _categories = [
    'All',
    'Action',
    'Adventure',
    'Fighting',
    'Racing',
    'Sports',
    'RPG',
    'Strategy',
  ];

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  List<Game> get games => List.unmodifiable(_games);

  List<String> get categories => List.unmodifiable(_categories);

  Future<void> loadGames() async {
    _isLoading = true;
    _hasError = false;

    notifyListeners();

    try {
      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      _games = [
        Game(
          id: '1',
          name: 'FIFA 23',
          category: 'Sports',
          icon: 'assets/images/fifa23.jpg',
          screenshot1: 'assets/images/fifa23_1.jpg',
          screenshot2: 'assets/images/fifa23_2.jpg',
          description:
              'Football game with realistic gameplay.',
          version: '1.0',
          size: '50 GB',
          downloadLink: 'https://example.com',
        ),
        Game(
          id: '2',
          name: 'Tekken 7',
          category: 'Fighting',
          icon: 'assets/images/tekken7.jpeg',
          screenshot1: 'assets/images/tekken7_1.jpg',
          screenshot2: 'assets/images/tekken7_2.jpg',
          description:
              'A popular fighting game.',
          version: '1.0',
          size: '45 GB',
          downloadLink: 'https://example.com',
        ),
      ];

      _hasError = false;
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Game> getGamesByCategory(String category) {
    if (category == 'All') {
      return List<Game>.from(_games);
    }

    return _games.where(
      (game) => game.category == category,
    ).toList();
  }
}
