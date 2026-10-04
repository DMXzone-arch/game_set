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
  bool isPressed = false;
  bool isDownloading = false;

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
    return AnimatedScale(
      scale: isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapCancel: () => setState(() => isPressed = false),
              onTapUp: (_) {
                setState(() => isPressed = false);
                unawaited(_openDetails());
              },
              child: AspectRatio(
                aspectRatio: 1.3,
                child: _buildGameIcon(context),
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
      ),
    );
  }

  Widget _buildGameIcon(BuildContext context) {
    final String imagePath = widget.game.icon.trim();
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
