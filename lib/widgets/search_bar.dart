import 'dart:ui';

import 'package:flutter/material.dart';

class GameSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const GameSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,

          // Search happens only when the user presses
          // the Search button on the keyboard.
          onSubmitted: onSubmitted,

          textInputAction: TextInputAction.search,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),

          decoration: InputDecoration(
            hintText: 'Search games...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.55,
              ),
            ),

            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF2196F3),
            ),

            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  )
                : null,

            filled: true,

            fillColor: Colors.white.withValues(
              alpha: 0.10,
            ),

            contentPadding:
                const EdgeInsets.symmetric(
              vertical: 17,
              horizontal: 8,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withValues(
                  alpha: 0.15,
                ),
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: Colors.white.withValues(
                  alpha: 0.15,
                ),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF2196F3),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}