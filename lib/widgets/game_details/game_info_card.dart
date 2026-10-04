import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/game.dart';

class GameInfoCard extends StatelessWidget {
  final Game game;
  final int? downloadCount;

  const GameInfoCard({
    super.key,
    required this.game,
    required this.downloadCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2196F3),
                    size: 21,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Game Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.category_outlined,
                      title: 'Category',
                      value: game.category,
                      fallback: 'Unknown',
                    ),
                  ),

                  _buildDivider(),

                  Expanded(
                    child: _InfoItem(
                      icon: Icons.update_rounded,
                      title: 'Version',
                      value: game.version,
                      fallback: 'N/A',
                    ),
                  ),

                  _buildDivider(),

                  Expanded(
                    child: _InfoItem(
                      icon: Icons.storage_rounded,
                      title: 'Size',
                      value: game.size,
                      fallback: 'Unknown',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.10)),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.download_outlined,
                    color: Color(0xFF2196F3),
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Downloads',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    downloadCount?.toString() ?? '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 55,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String fallback;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final String displayValue = value.trim().isEmpty ? fallback : value;

    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 21),

        const SizedBox(height: 8),

        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          displayValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: value.trim().isEmpty ? Colors.white38 : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
