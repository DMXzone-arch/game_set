import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/guest_mode_service.dart';
import 'login_view.dart';
import 'main_view.dart';

class EntryView extends StatefulWidget {
  const EntryView({super.key});

  @override
  State<EntryView> createState() => _EntryViewState();
}

class _EntryViewState extends State<EntryView> {
  final GuestModeService _guestMode = GuestModeService();

  Future<void> _continueAsGuest() async {
    await _guestMode.continueAsGuest();
    if (mounted) _openApp();
  }

  Future<void> _openEmailLogin() async {
    final bool? signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const LoginView()),
    );
    if (signedIn == true && mounted) _openApp();
  }

  void _openApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainView()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071426),
    body: Stack(
      children: [
        const Positioned(
          top: -120,
          right: -110,
          child: _EntryGlow(color: Color(0xFF1565C0)),
        ),
        const Positioned(
          bottom: -140,
          left: -110,
          child: _EntryGlow(color: Color(0xFF673AB7)),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: _glassPanel(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 34, 26, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
                            ),
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Welcome to GameSet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Find your next favorite game.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 15),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _openEmailLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Log in',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _continueAsGuest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .22),
                              ),
                            ),
                            child: const Text('Continue as guest'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 4),
                        const Text(
                          'A GameSet account is needed to save a wishlist.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _glassPanel(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: .11)),
        ),
        child: child,
      ),
    ),
  );
}

class _EntryGlow extends StatelessWidget {
  const _EntryGlow({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .14),
    ),
  );
}
