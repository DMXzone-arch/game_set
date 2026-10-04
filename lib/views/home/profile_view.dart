import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_profile_service.dart';
import '../../widgets/generated_avatar.dart';
import 'login_view.dart';
import 'settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final UserProfileService _profiles = UserProfileService();
  final TextEditingController _name = TextEditingController();
  bool _working = false;
  int _avatarId = 0;
  int _profileRevision = 0;
  String? _loadedUid;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String currentName) async {
    final String updatedName = _name.text.trim().isEmpty
        ? currentName
        : _name.text.trim();
    setState(() => _working = true);
    try {
      await _profiles.updateProfile(
        displayName: updatedName,
        avatarId: _avatarId,
      );
      if (!mounted) return;
      setState(() => _profileRevision++);
      _showMessage('Profile updated.');
    } catch (error) {
      if (mounted)
        _showMessage(
          'Could not save your profile. Check your connection and try again.',
        );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426),
      body: Stack(
        children: [
          const Positioned(
            top: -110,
            right: -80,
            child: _ProfileGlow(color: Color(0xFF1565C0)),
          ),
          const Positioned(
            bottom: 100,
            left: -110,
            child: _ProfileGlow(color: Color(0xFF673AB7)),
          ),
          SafeArea(
            child: StreamBuilder<User?>(
              stream: _profiles.authChanges(),
              builder: (context, snapshot) {
                final User? user = snapshot.data;
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Your GameSet account and preferences',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverList.list(
                        children: [
                          if (user == null)
                            _buildAccountForm()
                          else
                            _buildProfile(user),
                          const SizedBox(height: 22),
                          _section('App settings', [
                            _tile(
                              icon: Icons.tune_rounded,
                              title: 'App settings',
                              subtitle: 'About, support, and app information',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsView(),
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountForm() {
    return _panel(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const GeneratedAvatar(avatarId: 0, size: 66),
            const SizedBox(height: 16),
            const Text(
              'Welcome to GameSet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log in or create an account to manage your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LoginView()),
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Log in or create account'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can keep browsing GameSet without an account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(User user) {
    final Future<Map<String, dynamic>?> profileFuture = _profiles.fetchProfile(
      user.uid,
    );
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey(_profileRevision),
      future: profileFuture,
      builder: (context, snapshot) {
        final Map<String, dynamic> data = snapshot.data ?? const {};
        final String displayName =
            (data['displayName'] as String?)?.trim().isNotEmpty == true
            ? (data['displayName'] as String).trim()
            : (user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : 'GameSet player');
        final int avatarId = data['avatarId'] is num
            ? (data['avatarId'] as num).toInt().clamp(0, 4).toInt()
            : _avatarId;
        if (snapshot.hasData && _loadedUid != user.uid) {
          _loadedUid = user.uid;
          _name.text = displayName;
          _avatarId = avatarId;
        }
        final bool isAdmin = data['role'] == 'admin';
        return Column(
          children: [
            _panel(
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GeneratedAvatar(avatarId: _avatarId, size: 66),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? 'Email not available',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin) const _AdminBadge(),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Display name',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .75),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _input(
                      _name,
                      'Your name',
                      Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose your game icon',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _avatarChoices(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _working
                            ? null
                            : () => _saveProfile(displayName),
                        child: _working
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save profile'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _working ? null : _profiles.signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _avatarChoices() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List<Widget>.generate(
      5,
      (index) => GestureDetector(
        onTap: () => setState(() => _avatarId = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _avatarId == index ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: GeneratedAvatar(avatarId: index, size: 42),
        ),
      ),
    ),
  );

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onSubmitted,
  }) => TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    onSubmitted: onSubmitted,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .055),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .10)),
      ),
    ),
  );

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _panel(Column(children: children)),
    ],
  );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Icon(icon, color: const Color(0xFF64B5F6)),
    title: Text(
      title,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: Colors.white54, fontSize: 12),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
  );

  Widget _panel(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .075),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: child,
      ),
    ),
  );
}

class _ProfileGlow extends StatelessWidget {
  const _ProfileGlow({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 270,
    height: 270,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .12),
    ),
  );
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();
  @override
  Widget build(BuildContext context) => const Chip(
    avatar: Icon(Icons.verified_user_rounded, size: 15),
    label: Text('Admin'),
    visualDensity: VisualDensity.compact,
  );
}
