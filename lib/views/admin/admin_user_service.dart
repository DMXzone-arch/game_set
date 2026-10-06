import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarId,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final int avatarId;
  final String role;
  final DateTime? createdAt;

  factory AdminUserRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final Object? timestamp = data['createdAt'];
    return AdminUserRecord(
      id: id,
      email: data['email'] is String ? data['email'] as String : '',
      displayName: data['displayName'] is String
          ? data['displayName'] as String
          : '',
      avatarId: data['avatarId'] is num
          ? (data['avatarId'] as num).toInt().clamp(0, 4).toInt()
          : 0,
      role: data['role'] is String ? data['role'] as String : 'user',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}

Future<List<AdminUserRecord>> fetchAdminUserRecords({
  FirebaseFirestore? firestore,
}) async {
  final QuerySnapshot<Map<String, dynamic>> snapshot =
      await (firestore ?? FirebaseFirestore.instance).collection('users').get();
  final List<AdminUserRecord> users = snapshot.docs
      .map(
        (document) =>
            AdminUserRecord.fromFirestore(document.id, document.data()),
      )
      .toList();
  users.sort((first, second) {
    final DateTime firstDate =
        first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime secondDate =
        second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return secondDate.compareTo(firstDate);
  });
  return users;
}
