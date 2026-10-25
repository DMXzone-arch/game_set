import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/game.dart';
import '../services/game_repository.dart';
import '../views/home/game_details_view.dart';

class GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback? onDetailsClosed;

  const GameCard({super.key, required this.game, this.onDetailsClosed});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  static final Map<String, Future<String?>> _iconRequests = {};

  bool isDownloading = false;
  String? _loadedIcon;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(covariant GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _loadedIcon = null;
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    if (widget.game.icon.trim().isNotEmpty || widget.game.id.isEmpty) return;
    final Future<String?> request = _iconRequests.putIfAbsent(
      widget.game.id,
      () => GameRepository().fetchGameIcon(widget.game.id),
    );
    try {
      final String? icon = await request;
      if (mounted && icon != null) setState(() => _loadedIcon = icon);
    } catch (_) {
      _iconRequests.remove(widget.game.id);
    }
  }

  Future<void> _downloadGame() async {
    final Uri? url = Uri.tryParse(widget.game.downloadLink);

    if (url == null || (url.scheme != 'http' && url.scheme != 'https')) {
      _showMessage('This game does not have a valid download link.');
      return;
    }

    setState(() => isDownloading = true);
    _recordDownloadTap();

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Could not open the download website.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Something went wrong while opening the website.');
      }
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  void _recordDownloadTap() {
    if (widget.game.id.isEmpty) return;
    unawaited(
      GameRepository()
          .incrementDownloadCount(widget.game.id)
          .catchError((Object _) {}),
    );
  }

  Future<void> _openDetails() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GameDetailsView(game: widget.game),
      ),
    );
    if (mounted) widget.onDetailsClosed?.call();
  }

  void _showMessage(String message) {
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
    return Card(
      clipBehavior: Clip.none,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => unawaited(_openDetails()),
            child: AspectRatio(
              aspectRatio: 1.3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildGameIcon(context),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2196F3,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.game.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    _buildDownloadButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameIcon(BuildContext context) {
    final String imagePath =
        widget.game.icon.trim().isNotEmpty
            ? widget.game.icon.trim()
            : _loadedIcon?.trim() ?? '';
    final Widget fallback = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.gamepad, size: 36)),
    );
    Widget buildError(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) => fallback;

    if (imagePath.startsWith('https://') || imagePath.startsWith('http://')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 320,
        filterQuality: FilterQuality.low,
        errorBuilder: buildError,
      );
    }
    if (imagePath.isEmpty) return fallback;
    return Image.asset(
      imagePath,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: buildError,
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      height: 28,
      child: FilledButton(
        onPressed: isDownloading ? null : _downloadGame,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(
            0xFF1565C0,
          ).withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isDownloading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: 14),
                  SizedBox(width: 3),
                  Text(
                    'Download',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
