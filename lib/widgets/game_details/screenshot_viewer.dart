import 'package:flutter/material.dart';

class ScreenshotViewer extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const ScreenshotViewer({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  void _openViewer(BuildContext context) {
    if (imagePath.trim().isEmpty) {
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenScreenshot(imagePath: imagePath, heroTag: heroTag);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasImage ? () => _openViewer(context) : null,
      child: Hero(
        tag: heroTag,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: hasImage
                ? _buildScreenshotImage(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildErrorWidget(),
                  )
                : _buildErrorWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white.withValues(alpha: 0.06),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white38,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Screenshot unavailable',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FullscreenScreenshot extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const _FullscreenScreenshot({required this.imagePath, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: _buildScreenshotImage(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                            size: 60,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Screenshot unavailable',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildScreenshotImage(
  String imagePath, {
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  if (imagePath.startsWith('https://') || imagePath.startsWith('http://')) {
    return Image.network(imagePath, fit: fit, errorBuilder: errorBuilder);
  }
  return Image.asset(imagePath, fit: fit, errorBuilder: errorBuilder);
}
