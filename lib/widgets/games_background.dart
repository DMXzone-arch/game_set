import 'dart:ui';

import 'package:flutter/material.dart';

class GamesBackground extends StatelessWidget {
  const GamesBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF071426),
                Color(0xFF0B1020),
                Color(0xFF130A20),
              ],
            ),
          ),
        ),

        Positioned(
          top: -120,
          right: -100,
          child: _buildGlow(
            size: 320,
            color: Colors.blue,
          ),
        ),

        Positioned(
          top: 300,
          left: -160,
          child: _buildGlow(
            size: 350,
            color: Colors.deepPurple,
          ),
        ),

        Positioned(
          bottom: -150,
          right: -100,
          child: _buildGlow(
            size: 300,
            color: Colors.indigo,
          ),
        ),

        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 65,
              sigmaY: 65,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.17),
      ),
    );
  }
}