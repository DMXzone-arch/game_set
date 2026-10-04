import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../viewmodels/games_viewmodel.dart';
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
  final GamesViewModel _viewModel = GamesViewModel();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel.selectCategory(widget.initialCategory);
    _searchController.addListener(_onSearchTextChanged);
    _loadGames();
  }

  Future<void> _loadGames() => _viewModel.loadGames();

  void _onSearchTextChanged() {
    setState(() {});
  }

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

  void _returnToSearch() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchTextChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeBackground(),
        SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              final List<Game> games = _viewModel.filteredGames;
              final bool showGamesGrid =
                  !_viewModel.isLoading &&
                  !_viewModel.hasError &&
                  games.isNotEmpty;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
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
                        const SizedBox(height: 20),
                        GameSearchBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onSubmitted: _submitSearch,
                          onClear: _clearSearch,
                        ),
                        const SizedBox(height: 18),
                        CategorySelector(
                          categories: _viewModel.categories,
                          selectedCategory: _viewModel.selectedCategory,
                          onChanged: _selectCategory,
                        ),
                        const SizedBox(height: 22),
                        if (_viewModel.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF64B5F6),
                              ),
                            ),
                          )
                        else if (_viewModel.hasError)
                          _GamesError(onRetry: _loadGames)
                        else ...[
                          Text(
                            '${games.length} games',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (games.isEmpty) const _GamesEmptyState(),
                        ],
                      ],
                    ),
                  ),
                  if (showGamesGrid)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final int columns =
                              (constraints.crossAxisExtent / 190).floor().clamp(
                                2,
                                5,
                              );
                          return SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => GameCard(
                                key: ValueKey(games[index].id),
                                game: games[index],
                                onDetailsClosed: _returnToSearch,
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
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              );
            },
          ),
        ),
      ],
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
