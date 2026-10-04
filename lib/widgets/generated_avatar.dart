import 'package:flutter/material.dart';

/// Five locally drawn profile emblems. No user supplied image is required.
class GeneratedAvatar extends StatelessWidget {
  const GeneratedAvatar({super.key, required this.avatarId, this.size = 52});

  final int avatarId;
  final double size;

  static const List<Color> _colors = [
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFFEF5350),
  ];

  static const List<IconData> _icons = [
    Icons.sports_esports_rounded,
    Icons.rocket_launch_rounded,
    Icons.smart_toy_rounded,
    Icons.bolt_rounded,
    Icons.shield_moon_rounded,
  ];

  static Color colorFor(int id) => _colors[id.clamp(0, 4).toInt()];

  @override
  Widget build(BuildContext context) {
    final int index = avatarId.clamp(0, 4).toInt();
    final Color color = _colors[index];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.48),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16),
        ],
      ),
      child: Icon(_icons[index], color: Colors.white, size: size * 0.52),
    );
  }
}
