import 'dart:ui';

import 'package:flutter/material.dart';

import '../about_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
                          onTap: () {
                            // Secret admin access will be added later.
                          },
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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

              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
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
