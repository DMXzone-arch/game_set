import 'dart:ui';

import 'package:flutter/material.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF071426), Color(0xFF0B1020), Color(0xFF130A20)],
            ),
          ),
        ),
        const Positioned(
          top: -100,
          left: -80,
          child: _Glow(size: 260, color: Colors.blue),
        ),
        const Positioned(
          top: 280,
          right: -100,
          child: _Glow(size: 300, color: Colors.deepPurple),
        ),
        const Positioned(
          bottom: 80,
          left: -100,
          child: _Glow(size: 280, color: Colors.cyan),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
      ),
    );
  }
}
