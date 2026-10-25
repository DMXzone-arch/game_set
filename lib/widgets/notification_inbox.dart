import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/notification_service.dart';

Future<void> showNotificationInbox(
  BuildContext context,
  NotificationService service,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0B1B30),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => service.markAllAsRead(),
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: StreamBuilder<List<AppNotification>>(
                stream: service.watchNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    );
                  }
                  final List<AppNotification> items =
                      snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Text(
                        'No notifications yet. New games and app updates will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _Tile(item: items[index]),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final bool isAppUpdate = item.type == 'app_update';
    return Container(
      decoration: BoxDecoration(
        color: item.read
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFF1565C0).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              const Color(0xFF2196F3).withValues(alpha: 0.2),
          child: Icon(
            isAppUpdate
                ? Icons.system_update_rounded
                : Icons.sports_esports_rounded,
            color: const Color(0xFF64B5F6),
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.body,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _ago(item.createdAt),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        trailing: isAppUpdate && (item.apkUrl ?? '').isNotEmpty
            ? FilledButton(
                onPressed: () => _open(context),
                child: const Text('Update'),
              )
            : null,
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final Uri? uri = Uri.tryParse((item.apkUrl ?? '').trim());
    if (uri == null || uri.host.isEmpty) return;
    final bool ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the update link.'),
        ),
      );
    }
  }

  String _ago(DateTime time) {
    final Duration d = DateTime.now().difference(time);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
