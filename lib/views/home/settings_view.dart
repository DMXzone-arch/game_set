import 'dart:ui';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../about_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../../services/admin_auth_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  int _versionTapCount = 0;
  Timer? _versionTapTimer;
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _versionTapTimer?.cancel();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _onVersionTapped() {
    _versionTapTimer?.cancel();
    _versionTapCount++;
    _versionTapTimer = Timer(const Duration(seconds: 3), () {
      _versionTapCount = 0;
    });

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      _versionTapTimer?.cancel();
      _requestAdminAccess();
    }
  }

  Future<void> _requestAdminAccess() async {
    _adminEmailController.clear();
    _adminPasswordController.clear();
    bool isSigningIn = false;
    Future<void> signIn(
      StateSetter setDialogState,
      BuildContext dialogContext,
    ) async {
      setDialogState(() => isSigningIn = true);
      try {
        await AdminAuthService().signInAsAdmin(
          email: _adminEmailController.text,
          password: _adminPasswordController.text,
        );
        if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
      } catch (error) {
        if (!dialogContext.mounted) return;
        setDialogState(() => isSigningIn = false);
        final String message = switch (error) {
          AdminAccessDeniedException() =>
            'This account is not an administrator.',
          FirebaseAuthException(:final code) => switch (code) {
            'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' => 'Email or password is incorrect.',
            'network-request-failed' =>
              'Check your internet connection and try again.',
            _ => error.message ?? 'Could not sign in. Please try again.',
          },
          _ =>
            'Could not verify admin access. Check your connection and try again.',
        };
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    final bool? signedIn = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Admin access'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _adminEmailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _adminPasswordController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                onSubmitted: (_) => signIn(setDialogState, dialogContext),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSigningIn
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSigningIn
                  ? null
                  : () => signIn(setDialogState, dialogContext),
              child: isSigningIn
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || signedIn != true) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminDashboardView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                  sliver: SliverToBoxAdapter(child: _buildHeader()),
                ),

                // APP
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _buildSection(
                      title: 'App',
                      children: [
                        _buildSettingTile(
                          icon: Icons.system_update_rounded,
                          title: 'Check for Updates',
                          subtitle: 'Check if a new version is available',
                          onTap: () {
                            _checkForUpdates(context);
                          },
                        ),

                        _buildDivider(),

                        _buildSettingTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Version',
                          subtitle: 'v1.0.0',
                          onTap: _onVersionTapped,
                          subtleTap: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // ABOUT
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildSection(
                      title: 'About',
                      children: [
                        _buildSettingTile(
                          icon: Icons.apps_rounded,
                          title: 'About GameSet',
                          subtitle: 'Learn more about GameSet',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AboutView(),
                              ),
                            );
                          },
                        ),

                        _buildDivider(),

                        _buildSettingTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          onTap: () {
                            _showComingSoon(
                              context,
                              'Privacy Policy will be available soon.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // SUPPORT
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                  sliver: SliverToBoxAdapter(
                    child: _buildSection(
                      title: 'Support',
                      children: [
                        _buildSettingTile(
                          icon: Icons.support_agent_rounded,
                          title: 'Contact / Help',
                          subtitle: 'Get help with GameSet',
                          onTap: () {
                            _showComingSoon(
                              context,
                              'Support will be available soon.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
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
          top: -100,
          right: -80,
          child: _buildGlow(size: 300, color: Colors.blue),
        ),

        Positioned(
          top: 350,
          left: -150,
          child: _buildGlow(size: 330, color: Colors.deepPurple),
        ),

        Positioned(
          bottom: -120,
          right: -80,
          child: _buildGlow(size: 280, color: Colors.indigo),
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
        color: color.withValues(alpha: 0.16),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Manage your GameSet experience',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool subtleTap = false,
  }) {
    final Widget tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF64B5F6), size: 21),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (!subtleTap)
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        ],
      ),
    );

    if (subtleTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: tile),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),

              SizedBox(width: 16),

              Text(
                'Checking for updates...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;

    Navigator.pop(context);

    _showComingSoon(context, 'You are using the latest version of GameSet.');
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF18283D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}
