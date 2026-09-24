import 'dart:ui';

import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

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
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text(
                    'About GameSet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAppHeader(),

                      const SizedBox(height: 28),

                      _buildSection(
                        title: 'About',
                        child: const Text(
                          'GameSet is a game discovery app designed '
                          'to help users discover and explore games '
                          'in one place.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        title: 'Features',
                        child: Column(
                          children: [
                            _buildFeature(Icons.search_rounded, 'Search Games'),
                            _buildFeature(
                              Icons.category_rounded,
                              'Browse by Category',
                            ),
                            _buildFeature(
                              Icons.sports_esports_rounded,
                              'Discover Games',
                            ),
                            _buildFeature(
                              Icons.info_outline_rounded,
                              'View Game Details',
                            ),
                            _buildFeature(
                              Icons.photo_library_outlined,
                              'View Screenshots',
                            ),
                            _buildFeature(
                              Icons.download_rounded,
                              'Access Download Links',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        title: 'Developer',
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1565C0,
                                ).withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF64B5F6),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edmond Dumisan Banda',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Developer',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSection(
                        title: 'App Information',
                        child: Column(
                          children: [
                            _buildInfoRow('Version', 'v1.0.0'),
                            const SizedBox(height: 14),
                            _buildInfoRow('Release', '2026'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Center(
                        child: Text(
                          '© 2026 GameSet',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Center(
                        child: Text(
                          'All rights reserved.',
                          style: TextStyle(color: Colors.white30, fontSize: 11),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Icon(
            Icons.sports_esports_rounded,
            color: Color(0xFF2196F3),
            size: 48,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'GameSet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Play More • Discover More',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
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
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64B5F6), size: 21),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
}
