import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A single user-visible notification published by the admin app.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.gameId,
    this.version,
    this.buildNumber,
    this.apkUrl,
    this.releaseNotes,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final String? gameId;
  final String? version;
  final int? buildNumber;
  final String? apkUrl;
  final String? releaseNotes;
  final bool read;

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? const {};
    DateTime createdAt = DateTime.now();
    final Object? stamp = data['createdAt'];
    if (stamp is Timestamp) createdAt = stamp.toDate();
    return AppNotification(
      id: doc.id,
      title: data['title'] is String ? data['title'] as String : 'GameSet update',
      body: data['body'] is String ? data['body'] as String : '',
      type: data['type'] is String ? data['type'] as String : 'general',
      createdAt: createdAt,
      gameId: data['gameId'] is String ? data['gameId'] as String : null,
      version: data['version'] is String ? data['version'] as String : null,
      buildNumber:
          data['buildNumber'] is num ? (data['buildNumber'] as num).toInt() : null,
      apkUrl: data['apkUrl'] is String ? data['apkUrl'] as String : null,
      releaseNotes:
          data['releaseNotes'] is String ? data['releaseNotes'] as String : null,
      read: data['read'] == true,
    );
  }
}

/// Watches `notifications` and shows a system alert for new items.
class NotificationService extends ChangeNotifier {
  NotificationService({this._firestore});

  FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _lastSeenId;
  List<AppNotification> _notifications = const [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings ios = DarwinInitializationSettings();
      const LinuxInitializationSettings linux =
          LinuxInitializationSettings(defaultActionName: 'Open');
      const InitializationSettings settings = InitializationSettings(
        android: android,
        iOS: ios,
        macOS: ios,
        linux: linux,
      );
      await _local.initialize(settings: settings);
      if (!kIsWeb) {
        try {
          final AndroidFlutterLocalNotificationsPlugin? plugin = _local
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          await plugin?.requestNotificationsPermission();
          const AndroidNotificationChannel channel =
              AndroidNotificationChannel(
            'gameset_updates',
            'GameSet updates',
            description: 'Notifications for new games and app updates.',
            importance: Importance.high,
          );
          await plugin?.createNotificationChannel(channel);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Stream<List<AppNotification>> watchNotifications({int limit = 30}) {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromFirestore).toList());
  }

  Stream<List<AppNotification>> watchAndNotify() {
    return watchNotifications().map((list) {
      final List<AppNotification> prev = _notifications;
      _notifications = list;
      if (prev.isNotEmpty && list.isNotEmpty) {
        final Set<String> prevIds = prev.map((n) => n.id).toSet();
        for (final AppNotification item in list) {
          if (!prevIds.contains(item.id) && _lastSeenId != item.id) {
            _lastSeenId = item.id;
            showSystemNotification(item);
            break;
          }
        }
      } else if (list.isNotEmpty) {
        _lastSeenId ??= list.first.id;
      }
      notifyListeners();
      return list;
    });
  }

  Future<void> showSystemNotification(AppNotification n) async {
    try {
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        'gameset_updates',
        'GameSet updates',
        channelDescription: 'Notifications for new games and app updates.',
        importance: Importance.high,
        priority: Priority.high,
      );
      const DarwinNotificationDetails ios = DarwinNotificationDetails();
      const LinuxNotificationDetails linux = LinuxNotificationDetails();
      const NotificationDetails details = NotificationDetails(
        android: android,
        iOS: ios,
        macOS: ios,
        linux: linux,
      );
      await _local.show(
        id: n.id.hashCode,
        title: n.title,
        body: n.body.isEmpty ? 'Open GameSet to see what is new.' : n.body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final batch = _db.batch();
      for (final n in _notifications.where((n) => !n.read)) {
        batch.set(
          _db.collection('notifications').doc(n.id),
          {'read': true},
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Mark all read failed: $e');
    }
  }
}
