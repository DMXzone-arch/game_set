import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../widgets/search_bar.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/home_background.dart';
import '../../widgets/home_content.dart';
import '../../widgets/home_header.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final HomeViewModel viewModel = HomeViewModel();
  final NotificationService notifications = NotificationService();

  final TextEditingController searchController = TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  late final AnimationController _homeAnimationController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  late final Animation<double> _searchFade;
  late final Animation<double> _searchScale;

  late final Animation<double> _categoryFade;
  late final Animation<Offset> _categorySlide;

  @override
  void initState() {
    super.initState();

    _homeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFade = CurvedAnimation(
      parent: _homeAnimationController,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );

    _headerSlide = _slide(
      const Offset(0, -0.08),
      const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );

    _searchFade = CurvedAnimation(
      parent: _homeAnimationController,
      curve: const Interval(0.18, 0.50, curve: Curves.easeOut),
    );

    _searchScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _homeAnimationController,
        curve: const Interval(0.18, 0.50, curve: Curves.easeOutBack),
      ),
    );

    _categoryFade = CurvedAnimation(
      parent: _homeAnimationController,
      curve: const Interval(0.32, 0.65, curve: Curves.easeOut),
    );

    _categorySlide = _slide(
      const Offset(0, 0.08),
      const Interval(0.32, 0.65, curve: Curves.easeOutCubic),
    );

    _loadGames();
    _startNotifications();
  }

  void _startNotifications() {
    notifications.initialize().ignore();
    notifications.watchAndNotify().listen(
      (list) {
        if (!mounted || list.isEmpty) return;
        // In-app banner for the newest item is handled by system
        // notification; also show a snackbar when a genuinely new
        // item arrives while Home is visible. We track via service.
      },
      onError: (_) {},
    );
  }

  Animation<Offset> _slide(Offset begin, Curve curve) {
    return Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _homeAnimationController, curve: curve));
  }

  Future<void> _loadGames({bool forceRefresh = false}) async {
    await viewModel.loadGames(forceRefresh: forceRefresh);

    if (mounted &&
        _homeAnimationController.status != AnimationStatus.completed) {
      _homeAnimationController.forward();
    }
  }

  void _submitSearch(String value) {
    viewModel.submitSearch(value);
    searchFocusNode.unfocus();
    _restartAnimation();
  }

  void _clearSearch() {
    searchController.clear();
    viewModel.clearSearch();
    searchFocusNode.unfocus();
    _restartAnimation();
  }

  void _selectCategory(String category) {
    viewModel.selectCategory(category);
    _restartAnimation();
  }

  void _restartAnimation() {
    _homeAnimationController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _homeAnimationController.dispose();
    viewModel.dispose();
    notifications.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const HomeBackground(),

          SafeArea(
            child: AnimatedBuilder(
              animation: viewModel,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlideTransition(
                            position: _headerSlide,
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: HomeHeader(
                                notificationService: notifications,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _searchFade,
                            child: ScaleTransition(
                              scale: _searchScale,
                              child: GameSearchBar(
                                controller: searchController,
                                focusNode: searchFocusNode,
                                onSubmitted: _submitSearch,
                                onClear: _clearSearch,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SlideTransition(
                            position: _categorySlide,
                            child: FadeTransition(
                              opacity: _categoryFade,
                              child: CategorySelector(
                                categories: viewModel.categories,
                                selectedCategory: viewModel.selectedCategory,
                                onChanged: _selectCategory,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadGames(forceRefresh: true),
                        color: const Color(0xFF64B5F6),
                        backgroundColor: const Color(0xFF182236),
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: HomeContent(
                              key: ValueKey(
                                '${viewModel.selectedCategory}_'
                                '${viewModel.submittedSearchQuery}',
                              ),
                              games: viewModel.filteredGames,
                              mostDownloadedGames:
                                  viewModel.filteredMostDownloadedGames,
                              isLoading: viewModel.isLoading,
                              hasError: viewModel.hasError,
                              errorMessage: viewModel.errorMessage,
                              searchQuery: viewModel.submittedSearchQuery,
                              onRetry: () => _loadGames(forceRefresh: true),
                            ),
                          ),
                        ),
                      ),
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
}
