import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/models/game.dart';
import 'package:game_set/services/game_repository.dart';
import 'package:game_set/viewmodels/game_viewmodel.dart';

class _UnavailableGameRepository extends GameRepository {
  @override
  Future<List<Game>> fetchGames({bool forceRefresh = false}) async {
    throw StateError('Firestore unavailable');
  }

  @override
  Future<List<String>> fetchCategories({bool forceRefresh = false}) async {
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

  test('reports an error when the catalog cannot be loaded at all', () async {
    final GameViewModel viewModel = GameViewModel(
      repository: _UnavailableGameRepository(),
    );
    addTearDown(viewModel.dispose);

    await viewModel.loadGames();

    // With no data loaded there is nothing to fall back on, so the failure
    // must be surfaced rather than silently showing an empty catalog.
    expect(viewModel.hasError, isTrue);
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.games, isEmpty);
  });

  test('keeps existing games when a later refresh fails', () async {
    final _FlakyGameRepository repository = _FlakyGameRepository();
    final GameViewModel viewModel = GameViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await viewModel.loadGames();
    expect(viewModel.games.map((Game game) => game.name), ['Tekken 7']);
    expect(viewModel.hasError, isFalse);

    repository.failNextLoad = true;
    await viewModel.loadGames();

    // Already-loaded games stay visible during a transient outage.
    expect(viewModel.hasError, isFalse);
    expect(viewModel.games.map((Game game) => game.name), ['Tekken 7']);
  });
}

/// Fails on demand so a refresh can be tested after a successful load.
class _FlakyGameRepository extends GameRepository {
  bool failNextLoad = false;

  @override
  Future<List<Game>> fetchGames({bool forceRefresh = false}) async {
    if (failNextLoad) throw StateError('Firestore unavailable');
    return [_game('tekken-7', 'Tekken 7')];
  }

  @override
  Future<List<String>> fetchCategories({bool forceRefresh = false}) async =>
      ['Sports'];

  Game _game(String id, String name) => Game(
    id: id,
    name: name,
    category: 'Sports',
    icon: '',
    screenshot1: '',
    screenshot2: '',
    description: '',
    version: '1',
    size: '1 GB',
    downloadLink: 'https://example.com/$id',
  );
}

class _PopularGamesRepository extends GameRepository {
  _PopularGamesRepository(this.downloadCounts);

  final Map<String, int> downloadCounts;

  @override
  Future<List<Game>> fetchGames({bool forceRefresh = false}) async => [
    _game('new-game', 'New game'),
    _game('older-game', 'Older game'),
    _game('popular-game', 'Popular game'),
  ];

  @override
  Future<List<String>> fetchCategories({bool forceRefresh = false}) async =>
      ['Action'];

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
