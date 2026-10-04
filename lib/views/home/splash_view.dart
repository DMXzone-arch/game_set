import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/guest_mode_service.dart';
import 'entry_view.dart';
import 'main_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _loadingController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
        );

    _startSplash();
  }

  Future<void> _startSplash() async {
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    bool signedIn = false;
    try {
      signedIn = FirebaseAuth.instance.currentUser != null;
    } catch (_) {}
    final bool guestMode = await GuestModeService().hasChosenGuestMode();
    if (!mounted) return;
    final Widget firstPage = signedIn || guestMode
        ? const MainView()
        : const EntryView();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return firstPage;
        },
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );

          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      body: Stack(
        children: [
          _buildLiquidBackground(),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoOpacity,
                        child: SlideTransition(
                          position: _logoSlide,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _buildLogo(),
                  ),

                  const SizedBox(height: 18),

                  FadeTransition(
                    opacity: _logoOpacity,
                    child: Text(
                      'Play More • Discover More',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 42),

                  _buildLoadingIndicator(),

                  const SizedBox(height: 16),

                  Text(
                    'Loading GameSet...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.35),
                blurRadius: 35,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_esports_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),

        const SizedBox(height: 24),

        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
            children: [
              TextSpan(
                text: 'Game',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Set',
                style: TextStyle(color: Color(0xFF2196F3)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 34,
      height: 34,
      child: AnimatedBuilder(
        animation: _loadingController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _loadingController.value * 2 * 3.14159265359,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 3,
            ),
          ),
          child: const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 7,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidBackground() {
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

        Positioned(
          top: -130,
          left: -100,
          child: _buildGlow(size: 320, color: Colors.blue),
        ),

        Positioned(
          top: 260,
          right: -130,
          child: _buildGlow(size: 340, color: Colors.deepPurple),
        ),

        Positioned(
          bottom: -120,
          left: -100,
          child: _buildGlow(size: 300, color: Colors.cyan),
        ),

        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  Widget _buildGlow({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.20),
      ),
    );
  }
}
