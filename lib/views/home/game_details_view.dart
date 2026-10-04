import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/game.dart';
import '../../services/game_repository.dart';
import '../../widgets/game_details/game_description.dart';
import '../../widgets/game_details/game_details_header.dart';
import '../../widgets/game_details/game_info_card.dart';
import '../../widgets/game_details/screenshot_viewer.dart';

class GameDetailsView extends StatefulWidget {
  final Game game;

  const GameDetailsView({super.key, required this.game});

  @override
  State<GameDetailsView> createState() => _GameDetailsViewState();
}

class _GameDetailsViewState extends State<GameDetailsView>
    with SingleTickerProviderStateMixin {
  int? _downloadCount;

  late final AnimationController _animationController;

  late final Animation<double> _headerAnimation;
  late final Animation<double> _infoAnimation;
  late final Animation<double> _descriptionAnimation;
  late final Animation<double> _screenshotsAnimation;
  late final Animation<double> _downloadAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    _infoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.15, 0.60, curve: Curves.easeOutCubic),
    );

    _descriptionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.25, 0.70, curve: Curves.easeOutCubic),
    );

    _screenshotsAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    );

    _downloadAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _loadDownloadCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _downloadGame(BuildContext context) async {
    final Uri? url = Uri.tryParse(widget.game.downloadLink);

    if (url == null || (url.scheme != 'http' && url.scheme != 'https')) {
      _showMessage(context, 'This game does not have a valid download link.');
      return;
    }

    if (widget.game.id.isNotEmpty) {
      unawaited(_recordDownloadTap());
    }

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showMessage(context, 'Could not open the download website.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(
          context,
          'Something went wrong while opening the website.',
        );
      }
    }
  }

  Future<void> _loadDownloadCount() async {
    if (widget.game.id.isEmpty) {
      if (mounted) setState(() => _downloadCount = 0);
      return;
    }

    try {
      final Map<String, int> counts = await GameRepository()
          .fetchDownloadCounts([widget.game.id]);
      if (mounted) setState(() => _downloadCount = counts[widget.game.id] ?? 0);
    } catch (_) {}
  }

  Future<void> _recordDownloadTap() async {
    try {
      await GameRepository().incrementDownloadCount(widget.game.id);
      await _loadDownloadCount();
    } catch (_) {}
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF18283D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
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
                _buildAppBar(context),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _AnimatedSection(
                        animation: _headerAnimation,
                        child: GameDetailsHeader(game: widget.game),
                      ),

                      const SizedBox(height: 30),

                      _AnimatedSection(
                        animation: _infoAnimation,
                        child: GameInfoCard(
                          game: widget.game,
                          downloadCount: _downloadCount,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _AnimatedSection(
                        animation: _descriptionAnimation,
                        child: GameDescription(game: widget.game),
                      ),

                      const SizedBox(height: 30),

                      _AnimatedSection(
                        animation: _screenshotsAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              icon: Icons.photo_library_outlined,
                              title: 'Screenshots',
                            ),

                            const SizedBox(height: 14),

                            _buildScreenshots(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      _AnimatedSection(
                        animation: _downloadAnimation,
                        child: Column(
                          children: [
                            _buildDownloadButton(context),
                            _buildDownloadHint(),
                          ],
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 70,
      collapsedHeight: 70,
      backgroundColor: const Color(0xFF071426).withValues(alpha: 0.72),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
        child: _GlassCircleButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      title: Text(
        widget.game.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF64B5F6), size: 19),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshots() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ScreenshotContainer(
            child: ScreenshotViewer(
              imagePath: widget.game.screenshot1,
              heroTag: 'screenshot-1-${widget.game.id}',
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _ScreenshotContainer(
            child: ScreenshotViewer(
              imagePath: widget.game.screenshot2,
              heroTag: 'screenshot-2-${widget.game.id}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: () => _downloadGame(context),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.download_rounded, size: 22),
        label: const Text(
          'Download Game',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDownloadHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.40),
          ),
          const SizedBox(width: 6),
          Text(
            'Opens the official download website',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 11,
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
          top: -120,
          right: -100,
          child: _buildGlow(size: 320, color: Colors.blue),
        ),

        Positioned(
          top: 360,
          left: -150,
          child: _buildGlow(size: 340, color: Colors.deepPurple),
        ),

        Positioned(
          bottom: -180,
          right: -120,
          child: _buildGlow(size: 300, color: Colors.indigo),
        ),

        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
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
        color: color.withValues(alpha: 0.17),
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedSection({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassCircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _ScreenshotContainer extends StatelessWidget {
  final Widget child;

  const _ScreenshotContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}
