import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/models/game.dart';
import 'package:game_set/services/game_repository.dart';
import 'package:game_set/viewmodels/game_viewmodel.dart';

class _UnavailableGameRepository extends GameRepository {
  @override
  Future<List<Game>> fetchGames() async {
    throw StateError('Firestore unavailable');
  }

  @override
  Future<List<String>> fetchCategories() async {
    throw StateError('Firestore unavailable');
  }
}

void main() {
  test('ranks games with downloads and omits games with none', () async {
    final GameViewModel viewModel = GameViewModel(
      repository: _PopularGamesRepository({
        'new-game': 0,
        'older-game': 3,
        'popular-game': 8,
      }),
    );
    addTearDown(viewModel.dispose);

    await viewModel.loadGames();

    expect(viewModel.mostDownloadedGames.map((game) => game.id), [
      'popular-game',
      'older-game',
    ]);
  });

  test('keeps fixture games visible when Firestore is unavailable', () async {
    final GameViewModel viewModel = GameViewModel(
      repository: _UnavailableGameRepository(),
    );
    addTearDown(viewModel.dispose);

    await viewModel.loadGames();

    expect(viewModel.hasError, isFalse);
    expect(viewModel.games.map((game) => game.name), contains('FIFA 23'));
    expect(viewModel.games.map((game) => game.name), contains('Tekken 7'));
    expect(viewModel.categories, contains('Sports'));
  });
}

class _PopularGamesRepository extends GameRepository {
  _PopularGamesRepository(this.downloadCounts);

  final Map<String, int> downloadCounts;

  @override
  Future<List<Game>> fetchGames() async => [
    _game('new-game', 'New game'),
    _game('older-game', 'Older game'),
    _game('popular-game', 'Popular game'),
  ];

  @override
  Future<List<String>> fetchCategories() async => ['Action'];

  @override
  Future<Map<String, int>> fetchDownloadCounts(List<String> gameIds) async =>
      downloadCounts;

  Game _game(String id, String name) => Game(
    id: id,
    name: name,
    category: 'Action',
    icon: '',
    screenshot1: '',
    screenshot2: '',
    description: '',
    version: '1',
    size: '1 GB',
    downloadLink: 'https://example.com/$id',
  );
}
