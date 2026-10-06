import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/game_card.dart';
import 'login_view.dart';

class WishlistView extends StatefulWidget {
  const WishlistView({super.key});

  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  final WishlistService _wishlist = WishlistService();
  StreamSubscription<User?>? _authSubscription;
  Future<List<Game>> _games = Future<List<Game>>.value(const []);
  String? _activeUid;

  @override
  void initState() {
    super.initState();
    _activeUid = _currentUid;
    _games = _wishlist.fetchGames();
    // Reload when the account changes so one user's wishlist is never shown
    // to another (or to a signed-out visitor).
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      final String? nextUid = user != null && !user.isAnonymous
          ? user.uid
          : null;
      if (nextUid == _activeUid) return;
      if (!mounted) return;
      setState(() {
        _activeUid = nextUid;
        _games = _wishlist.fetchGames();
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String? get _currentUid {
    final User? user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous ? user.uid : null;
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _activeUid = _currentUid;
        _games = _wishlist.fetchGames();
      });
    }
  }

  Future<void> _openLogin() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const LoginView()));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAccount = _currentUid != null;
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
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
            if (!hasAccount)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _AccountRequired(onLogin: _openLogin),
              )
            else
              FutureBuilder<List<Game>>(
                future: _games,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _WishlistMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load your wishlist',
                        detail: 'Check your connection and try again.',
                        action: TextButton(
                          onPressed: _reload,
                          child: const Text('Try again'),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final List<Game> games = snapshot.data!;
                  if (games.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _WishlistMessage(
                        icon: Icons.favorite_border_rounded,
                        title: 'Your wishlist is empty',
                        detail:
                            'Open a game and tap the heart to save it here.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                    sliver: SliverGrid.builder(
                      itemCount: games.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.77,
                          ),
                      itemBuilder: (context, index) => GameCard(
                        game: games[index],
                        onDetailsClosed: _reload,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
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
