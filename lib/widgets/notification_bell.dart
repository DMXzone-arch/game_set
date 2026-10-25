import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'notification_inbox.dart';

/// Bell icon with unread badge + inbox sheet.
class NotificationBell extends StatelessWidget {
  const NotificationBell({required this.service, super.key});

  final NotificationService service;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final int unread = service.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => showNotificationInbox(context, service),
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 26,
              ),
              tooltip: 'Notifications',
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
