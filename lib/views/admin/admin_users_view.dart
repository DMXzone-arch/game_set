import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/user_profile_service.dart';
import '../../widgets/generated_avatar.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  late Future<List<AdminUserRecord>> _users;

  @override
  void initState() {
    super.initState();
    _users = fetchAdminUserRecords();
  }

  void _reload() => setState(() => _users = fetchAdminUserRecords());

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071426),
    appBar: AppBar(
      backgroundColor: const Color(0xFF071426),
      foregroundColor: Colors.white,
      title: const Text('User records'),
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: Stack(
      children: [
        const Positioned(top: -130, right: -100, child: _UsersGlow()),
        FutureBuilder<List<AdminUserRecord>>(
          future: _users,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Colors.white54,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load user records.',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check your connection and confirm that Firestore rules allow admins to read users.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _reload,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<AdminUserRecord> users = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  Text(
                    '${users.length} ${users.length == 1 ? 'account' : 'accounts'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (users.isEmpty)
                    const _EmptyUsers()
                  else
                    ...users.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _UserCard(user: user),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final AdminUserRecord user;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .075),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .09)),
        ),
        child: Row(
          children: [
            GeneratedAvatar(avatarId: user.avatarId, size: 48),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isEmpty
                        ? 'GameSet player'
                        : user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email.isEmpty ? 'No email on record' : user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Joined ${_date(user.createdAt)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (user.role == 'admin')
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF64B5F6),
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  String _date(DateTime? date) {
    if (date == null) return 'date unavailable';
    final DateTime local = date.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.people_outline_rounded, color: Colors.white54, size: 40),
        SizedBox(height: 12),
        Text(
          'No user profiles yet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          'New accounts will appear here after signing up.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    ),
  );
}

class _UsersGlow extends StatelessWidget {
  const _UsersGlow();
  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    height: 280,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF1565C0).withValues(alpha: .13),
    ),
  );
}
