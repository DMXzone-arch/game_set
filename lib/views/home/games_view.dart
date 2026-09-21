import 'package:flutter/material.dart';

import '../../viewmodels/games_viewmodel.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/game_card.dart';
import '../../widgets/games_background.dart';
import '../../widgets/search_bar.dart';

class GamesView extends StatefulWidget {
  const GamesView({super.key});

  @override
  State<GamesView> createState() => _GamesViewState();
}

class _GamesViewState extends State<GamesView>
    with SingleTickerProviderStateMixin {
  final GamesViewModel viewModel = GamesViewModel();

  final TextEditingController searchController =
      TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  late final AnimationController _animationController;

  late final Animation<double> _headerAnimation;
  late final Animation<double> _searchAnimation;
  late final Animation<double> _categoryAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.0,
        0.35,
        curve: Curves.easeOutCubic,
      ),
    );

    _searchAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.15,
        0.50,
        curve: Curves.easeOutCubic,
      ),
    );

    _categoryAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.30,
        0.65,
        curve: Curves.easeOutCubic,
      ),
    );

    viewModel.loadGames().then((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _animationController.dispose();
    viewModel.dispose();

    super.dispose();
  }

  void _submitSearch(String value) {
    viewModel.submitSearch(value);
    searchFocusNode.unfocus();
  }

  void _clearSearch() {
    searchController.clear();
    viewModel.clearSearch();
    searchFocusNode.unfocus();
  }

  void _selectCategory(String category) {
    viewModel.selectCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GamesBackground(),

          SafeArea(
            child: AnimatedBuilder(
              animation: viewModel,
              builder: (context, _) {
                if (viewModel.isLoading) {
                  return _buildLoadingState();
                }

                if (viewModel.hasError) {
                  return _buildErrorState();
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        20,
                        16,
                        24,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _headerAnimation,
                          child: _buildHeader(),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _searchAnimation,
                          child: _buildSearch(),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        24,
                        16,
                        8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _categoryAnimation,
                          child: CategorySelector(
                            categories: viewModel.categories,
                            selectedCategory:
                                viewModel.selectedCategory,
                            onChanged: _selectCategory,
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        18,
                        16,
                        110,
                      ),
                      sliver: _buildGamesGrid(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Games',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Browse our complete game collection',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.60),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return GameSearchBar(
      controller: searchController,
      focusNode: searchFocusNode,
      onSubmitted: _submitSearch,
      onClear: _clearSearch,
    );
  }

  Widget _buildGamesGrid() {
    final games = viewModel.filteredGames;

    if (games.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final game = games[index];

          return GameCard(
            game: game,
          );
        },
        childCount: games.length,
      ),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool searching =
        viewModel.submittedSearchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(
            searching
                ? Icons.search_off_rounded
                : Icons.sports_esports_outlined,
            color: Colors.white38,
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            searching
                ? 'No games found'
                : 'No games available',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try another search.'
                : 'Games will appear here when available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white38,
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: viewModel.loadGames,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}