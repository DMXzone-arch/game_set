import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'notification_bell.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({this.notificationService, super.key});

  final NotificationService? notificationService;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GameSet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Play More • Discover More',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (notificationService != null)
          NotificationBell(service: notificationService!),
      ],
    );
  }
}
