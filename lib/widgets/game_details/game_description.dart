import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/game.dart';

class GameDescription extends StatelessWidget {
  final Game game;

  const GameDescription({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDescription =
        game.description.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Color(0xFF2196F3),
                    size: 21,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'About This Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Text(
                hasDescription
                    ? game.description
                    : 'No description is available for this game yet.',
                style: TextStyle(
                  color: hasDescription
                      ? Colors.white.withValues(alpha: 0.72)
                      : Colors.white38,
                  fontSize: 14,
                  height: 1.65,
                  fontStyle: hasDescription
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}