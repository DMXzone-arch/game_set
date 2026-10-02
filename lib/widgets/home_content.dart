import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/game.dart';
import 'game_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.games,
    required this.mostDownloadedGames,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    required this.searchQuery,
    required this.onRetry,
  });

  final List<Game> games;
  final List<Game> mostDownloadedGames;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String searchQuery;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingContent();
    if (hasError) {
      return _ErrorContent(onRetry: onRetry, message: errorMessage);
    }

    final searching = searchQuery.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (searching) ...[
          Text(
            games.length == 1 ? '1 game found' : '${games.length} games found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
        ],
        _GameSection(
          title: 'Recently Added',
          icon: Icons.access_time_rounded,
          games: games,
          emptyMessage: searching ? 'No games found' : 'No games available',
          emptyDescription: searching
              ? 'Try searching for another game.'
              : 'Games will appear here when they are added.',
          emptyIcon: searching
              ? Icons.search_off_rounded
              : Icons.sports_esports_outlined,
        ),
        const SizedBox(height: 32),
        _GameSection(
          title: 'Most Downloaded',
          icon: Icons.local_fire_department_rounded,
          games: mostDownloadedGames,
          emptyMessage: searching
              ? 'No downloaded games found'
              : 'No downloads yet',
          emptyDescription: searching
              ? 'Try a different game name.'
              : 'Popular games will appear here.',
          emptyIcon: searching
              ? Icons.search_off_rounded
              : Icons.download_outlined,
        ),
      ],
    );
  }
}

class _GameSection extends StatelessWidget {
  const _GameSection({
    required this.title,
    required this.icon,
    required this.games,
    required this.emptyMessage,
    required this.emptyDescription,
    required this.emptyIcon,
  });

  final String title;
  final IconData icon;
  final List<Game> games;
  final String emptyMessage;
  final String emptyDescription;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (games.isEmpty)
          _EmptyState(
            message: emptyMessage,
            description: emptyDescription,
            icon: emptyIcon,
          )
        else
          SizedBox(
            height: 245,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: games.length,
              separatorBuilder: (_, index) => const SizedBox(width: 14),
              itemBuilder: (_, index) => SizedBox(
                width: 175,
                child: GameCard(
                  key: ValueKey(games[index].id),
                  game: games[index],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.description,
    required this.icon,
  });

  final String message;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: const Color(0xFF2196F3)),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _LoadingLabel(),
        SizedBox(height: 22),
        _LoadingSection(),
        SizedBox(height: 32),
        _LoadingSection(),
      ],
    );
  }
}

class _LoadingLabel extends StatelessWidget {
  const _LoadingLabel();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.sync, color: Color(0xFF2196F3)),
      const SizedBox(width: 12),
      Text(
        'Loading games...',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 150,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 245,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, index) => const SizedBox(width: 14),
          itemBuilder: (_, index) => const _LoadingCard(),
        ),
      ),
    ],
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Container(height: 135, color: Colors.white.withValues(alpha: 0.10)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 70,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 20),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'We couldn\'t load the games right now.\nPlease check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
