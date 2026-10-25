import 'package:flutter/material.dart';

import '../../viewmodels/wishlist_viewmodel.dart';
import '../../widgets/game_card.dart';
import 'login_view.dart';

class WishlistView extends StatefulWidget {
  const WishlistView({super.key});

  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  final WishlistViewModel _viewModel = WishlistViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const LoginView()));
    await _viewModel.loadGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final Widget content;
    if (!_viewModel.hasAccount) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: _AccountRequired(onLogin: _openLogin),
      );
    } else if (_viewModel.errorMessage != null) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: _WishlistMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load your wishlist',
          detail: 'Check your connection and try again.',
          action: TextButton(
            onPressed: _viewModel.loadGames,
            child: const Text('Try again'),
          ),
        ),
      );
    } else if (_viewModel.isLoading) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_viewModel.games.isEmpty) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: _WishlistMessage(
          icon: Icons.favorite_border_rounded,
          title: 'Your wishlist is empty',
          detail: 'Open a game and tap the heart to save it here.',
        ),
      );
    } else {
      final games = _viewModel.games;
      content = SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
        sliver: SliverGrid.builder(
          itemCount: games.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 0.77,
          ),
          itemBuilder: (context, index) => GameCard(
            game: games[index],
            onDetailsClosed: _viewModel.loadGames,
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 26, 20, 18),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wishlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Keep the games you want to play close.',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _AccountRequired extends StatelessWidget {
  const _AccountRequired({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 100),
      child: _WishlistMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to use your wishlist',
        detail: 'Create an account or sign in to save games across sessions.',
        action: FilledButton.icon(
          onPressed: onLogin,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Log in or create account'),
        ),
      ),
    ),
  );
}

class _WishlistMessage extends StatelessWidget {
  const _WishlistMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF64B5F6), size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}
