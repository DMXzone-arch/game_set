import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../models/game.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/game_card.dart';
import '../../widgets/home_background.dart';
import '../../widgets/search_bar.dart';

class GamesView extends StatefulWidget {
  const GamesView({
    super.key,
    this.initialCategory = 'All',
    this.onCategoryChanged,
  });

  final String initialCategory;
  final ValueChanged<String>? onCategoryChanged;

  @override
  State<GamesView> createState() => _GamesViewState();
}

class _GamesViewState extends State<GamesView> {
  final HomeViewModel _viewModel = HomeViewModel(loadPopularGames: false);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel.selectCategory(widget.initialCategory);
    _loadGames();
  }

  Future<void> _loadGames({bool forceRefresh = false}) =>
      _viewModel.loadGames(forceRefresh: forceRefresh);

  void _submitSearch(String query) {
    _viewModel.submitSearch(query);
    _searchFocusNode.unfocus();
  }

  void _selectCategory(String category) {
    _viewModel.selectCategory(category);
    widget.onCategoryChanged?.call(category);
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.clearSearch();
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const RepaintBoundary(child: HomeBackground()),
        SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              final List<Game> games = _viewModel.filteredGames;
              final bool showGamesGrid =
                  !_viewModel.isLoading &&
                  !_viewModel.hasError &&
                  games.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, _, _) => GameSearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onSubmitted: _submitSearch,
                        onClear: _clearSearch,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _loadGames(forceRefresh: true),
                      color: const Color(0xFF64B5F6),
                      backgroundColor: const Color(0xFF182236),
                      child: CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        scrollCacheExtent: const ScrollCacheExtent.pixels(100),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                            sliver: SliverList.list(
                              children: [
                                const Text(
                                  'All Games',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Browse the full GameSet catalog',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                CategorySelector(
                                  categories: _viewModel.categories,
                                  selectedCategory: _viewModel.selectedCategory,
                                  onChanged: _selectCategory,
                                ),
                                if (!_viewModel.isLoading &&
                                    !_viewModel.hasError) ...[
                                  const SizedBox(height: 18),
                                  Text(
                                    '${games.length} games',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ],
                            ),
                          ),
                          if (_viewModel.isLoading)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                110,
                              ),
                              sliver: SliverLayoutBuilder(
                                builder: (context, constraints) {
                                  final int columns =
                                      (constraints.crossAxisExtent / 190)
                                          .floor()
                                          .clamp(2, 5);
                                  return SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => const _GameCardLoading(),
                                      childCount: columns * 2,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 14,
                                          mainAxisExtent: 245,
                                        ),
                                  );
                                },
                              ),
                            )
                          else if (_viewModel.hasError)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _GamesError(
                                onRetry: () => _loadGames(forceRefresh: true),
                              ),
                            )
                          else if (games.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _GamesEmptyState(),
                            )
                          else if (showGamesGrid)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                110,
                              ),
                              sliver: SliverLayoutBuilder(
                                builder: (context, constraints) {
                                  final int columns =
                                      (constraints.crossAxisExtent / 190)
                                          .floor()
                                          .clamp(2, 5);
                                  return SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => GameCard(
                                        key: ValueKey(games[index].id),
                                        game: games[index],
                                      ),
                                      childCount: games.length,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 14,
                                          mainAxisExtent: 245,
                                        ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameCardLoading extends StatelessWidget {
  const _GameCardLoading();

  @override
  Widget build(BuildContext context) {
    final Color fill = Colors.white.withValues(alpha: 0.08);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101D31),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Icon(Icons.sports_esports_rounded,
                    color: Colors.white24, size: 32),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 100, color: fill),
                const SizedBox(height: 9),
                Container(height: 22, width: 72, color: fill),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GamesError extends StatelessWidget {
  const _GamesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Colors.white60,
              size: 34,
            ),
            const SizedBox(height: 12),
            const Text(
              'Games are unavailable right now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesEmptyState extends StatelessWidget {
  const _GamesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.sports_esports_outlined,
              color: Colors.white54,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              'No games match your search',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}
