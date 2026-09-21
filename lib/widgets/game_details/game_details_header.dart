import 'package:flutter/material.dart';

import '../../models/game.dart';

class GameDetailsHeader extends StatelessWidget {
  final Game game;

  const GameDetailsHeader({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final String gameName = _displayValue(
      game.name,
      fallback: 'Unknown Game',
    );

    final String category = _displayValue(
      game.category,
      fallback: 'Uncategorized',
    );

    return Column(
      children: [
        Hero(
          tag: 'game-icon-${game.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              game.icon,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return _buildFallbackIcon();
              },
            ),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          gameName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(
              alpha: 0.15,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2196F3).withValues(
                alpha: 0.15,
              ),
            ),
          ),
          child: Text(
            category,
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: const Icon(
        Icons.sports_esports_rounded,
        color: Colors.white54,
        size: 52,
      ),
    );
  }

  String _displayValue(
    String value, {
    required String fallback,
  }) {
    if (value.trim().isEmpty) {
      return fallback;
    }

    return value;
  }
}