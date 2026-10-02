import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/admin_auth_service.dart';
import '../../services/game_repository.dart';
import 'admin_categories_view.dart';
import 'admin_downloads_view.dart';
import 'admin_games_view.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  static const Color _background = Color(0xFF071426);
  static const Color _accent = Color(0xFF64B5F6);

  @override
  Widget build(BuildContext context) {
    final GameRepository repository = GameRepository();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('Admin'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AdminAuthService().signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -90,
            child: _AdminGlow(color: Color(0xFF1565C0)),
          ),
          SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  sliver: SliverList.list(
                    children: [
                      const Text(
                        'Control room',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage the GameSet catalog and activity.',
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 22),
                      _AdminOverview(repository: repository),
                      const SizedBox(height: 28),
                      const Text(
                        'Management',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AdminNavigationTile(
                        icon: Icons.sports_esports_rounded,
                        title: 'Games',
                        subtitle: 'Add, edit, publish, or remove games',
                        onTap: () => _openPage(context, const AdminGamesView()),
                      ),
                      const SizedBox(height: 10),
                      _AdminNavigationTile(
                        icon: Icons.category_rounded,
                        title: 'Categories',
                        subtitle: 'Organize the catalog',
                        onTap: () =>
                            _openPage(context, const AdminCategoriesView()),
                      ),
                      const SizedBox(height: 10),
                      _AdminNavigationTile(
                        icon: Icons.bar_chart_rounded,
                        title: 'Downloads',
                        subtitle: 'Review download counts by game',
                        onTap: () =>
                            _openPage(context, const AdminDownloadsView()),
                      ),
                      const SizedBox(height: 18),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: _accent,
                                size: 19,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sign in with a Firebase Auth account assigned the admin role in Firestore.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.repository});

  final GameRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminOverviewData>(
      future: repository.fetchAdminOverview(),
      builder: (context, snapshot) {
        final AdminOverviewData? data = snapshot.data;
        return Row(
          children: [
            Expanded(
              child: _OverviewMetric(
                label: 'Games',
                value: data?.gameCount.toString() ?? '—',
                icon: Icons.sports_esports_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewMetric(
                label: 'Categories',
                value: data?.categoryCount.toString() ?? '—',
                icon: Icons.category_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewMetric(
                label: 'Downloads',
                value: data?.downloadCount.toString() ?? '—',
                icon: Icons.download_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64B5F6), size: 20),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AdminNavigationTile extends StatelessWidget {
  const _AdminNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF64B5F6), size: 23),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminGlow extends StatelessWidget {
  const _AdminGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: Container(
          width: 320,
          height: 320,
          color: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
