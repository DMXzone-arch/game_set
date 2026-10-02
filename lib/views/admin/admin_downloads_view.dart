import 'package:flutter/material.dart';

import '../../services/game_repository.dart';

class AdminDownloadsView extends StatefulWidget {
  const AdminDownloadsView({super.key});

  @override
  State<AdminDownloadsView> createState() => _AdminDownloadsViewState();
}

class _AdminDownloadsViewState extends State<AdminDownloadsView> {
  final GameRepository _repository = GameRepository();
  late Future<List<AdminDownloadEntry>> _downloadsFuture;

  @override
  void initState() {
    super.initState();
    _downloadsFuture = _repository.fetchDownloadEntries();
  }

  void _refresh() {
    setState(() => _downloadsFuture = _repository.fetchDownloadEntries());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        foregroundColor: Colors.white,
        title: const Text('Downloads'),
      ),
      body: FutureBuilder<List<AdminDownloadEntry>>(
        future: _downloadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DownloadsMessage(
              title: 'Download data unavailable',
              message: 'Check Firebase setup and Firestore permissions.',
              onRetry: _refresh,
            );
          }
          final List<AdminDownloadEntry> entries = snapshot.data ?? const [];
          final int total = entries.fold<int>(
            0,
            (sum, entry) => sum + entry.count,
          );
          if (entries.isEmpty) {
            return _DownloadsMessage(
              title: 'No downloads recorded',
              message:
                  'Counts will appear here when download tracking is connected.',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF64B5F6).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total downloads',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'By game',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                for (final AdminDownloadEntry entry in entries) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sports_esports_outlined,
                          color: Color(0xFF64B5F6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.gameName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Text(
                          '${entry.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DownloadsMessage extends StatelessWidget {
  const _DownloadsMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF64B5F6),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
