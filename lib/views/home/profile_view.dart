import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/guest_mode_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/generated_avatar.dart';
import 'entry_view.dart';
import 'login_view.dart';
import 'settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final UserProfileService _profiles = UserProfileService();
  final GuestModeService _guestMode = GuestModeService();
  final TextEditingController _name = TextEditingController();
  bool _working = false;
  bool _editing = false;
  bool _awaitingSave = false;
  bool _sendingVerification = false;

  /// Whether the displayed profile values are confirmed persisted.
  /// Drives the save button label so failed writes are never called "Saved".
  bool _saveSucceeded = false;
  bool _savedProfileExists = false;

  /// The icon currently selected in the UI, which may not be persisted yet.
  int _avatarId = 0;

  /// The last icon value confirmed by Firestore. The UI falls back to this
  /// whenever a save fails, so the screen never claims an unsaved icon.
  int _savedAvatarId = 0;

  /// The last display name confirmed by Firestore, restored on save failure.
  String _savedDisplayName = '';

  int _profileRevision = 0;
  String? _hydratedUid;
  int _hydratedRevision = -1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Saves the selected icon and display name together.
  Future<void> _saveProfile() async {
    final String targetName = _name.text.trim();
    final int targetAvatarId = _avatarId;
    setState(() {
      _working = true;
      _awaitingSave = true;
    });
    try {
      await _profiles.updateProfile(
        displayName: targetName,
        avatarId: targetAvatarId,
      );
      if (!mounted) return;
      setState(() {
        _savedAvatarId = targetAvatarId;
        _savedDisplayName = targetName;
        _savedProfileExists = true;
        _saveSucceeded = true;
        _editing = false;
        _profileRevision++;
      });
      _showMessage('Profile saved.');
    } catch (error, stackTrace) {
      debugPrint('Profile save FAILED: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
      if (mounted) {
        setState(() {
          _avatarId = _savedAvatarId;
          _name.text = _savedDisplayName;
          _saveSucceeded = false;
        });
        _showMessage(_describeSaveError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _awaitingSave = false;
        });
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _avatarId = _savedAvatarId;
      _name.text = _savedDisplayName;
      _saveSucceeded = _savedProfileExists;
    });
  }

  Future<void> _signOut() async {
    await _profiles.signOut();
    await _guestMode.clearGuestChoice();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const EntryView()),
      (_) => false,
    );
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
            : _savedAvatarId;
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError &&
            (_hydratedUid != user.uid ||
                _hydratedRevision != _profileRevision)) {
          _hydratedUid = user.uid;
          _hydratedRevision = _profileRevision;
          _name.text = displayName;
          _avatarId = avatarId;
          _savedAvatarId = avatarId;
          _savedDisplayName = displayName;
          _savedProfileExists = snapshot.hasData;
          _saveSucceeded = snapshot.hasData;
        }
        // While editing (and right after a save) the card shows the in-progress
        // values, so the name and icon reflect what is being changed. Outside
        // edit mode it always shows the values confirmed by Firestore.
        final String shownName = _editing
            ? (_name.text.trim().isEmpty
                  ? _savedDisplayName
                  : _name.text.trim())
            : (_saveSucceeded ? _savedDisplayName : displayName);
        final int shownAvatarId = _editing ? _avatarId : _savedAvatarId;
        return Column(
          children: [
            _panel(
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (snapshot.hasError)
                      _profileError(),
                    if (snapshot.hasError || _awaitingSave)
                      const SizedBox(height: 12),
                    Row(
                      children: [
                        GeneratedAvatar(avatarId: shownAvatarId, size: 66),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shownName,
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
                              if (user.email != null &&
                                  !user.emailVerified) ...[
                                const SizedBox(height: 6),
                                _verifyEmailAction(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_editing) ...[
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
                        errorText: _nameError,
                        onChanged: (_) => setState(() {
                          _saveSucceeded = false;
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your email is managed by Google or your sign-in method and cannot be changed here.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .38),
                          fontSize: 11.5,
                        ),
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
                          onPressed: _working || _nameError != null
                              ? null
                              : () => _saveProfile(),
                          child: _working
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _hasUnsavedChanges
                                      ? 'Save changes'
                                      : _saveSucceeded
                                      ? 'Saved'
                                      : 'Not saved',
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: _working ? null : _cancelEditing,
                        child: const Text('Cancel'),
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              snapshot.connectionState ==
                                      ConnectionState.done &&
                                  !snapshot.hasError
                              ? () => setState(() => _editing = true)
                              : null,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit profile'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _working ? null : _signOut,
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

  Widget _verifyEmailAction() {
    return Row(
      children: [
        const Icon(
          Icons.mark_email_unread_outlined,
          size: 14,
          color: Colors.amberAccent,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Email not verified',
            style: TextStyle(
              color: Colors.amberAccent.withValues(alpha: .95),
              fontSize: 11.5,
            ),
          ),
        ),
        TextButton(
          onPressed: _sendingVerification ? null : _sendVerificationEmail,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 28),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            _sendingVerification ? 'Sending...' : 'Verify',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _sendingVerification = true);
    try {
      await _profiles.sendEmailVerification();
      if (!mounted) return;
      _showMessage('Verification email sent. Check your inbox.');
    } catch (_) {
      if (mounted) {
        _showMessage('Could not send the verification email. Try again later.');
      }
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  Widget _profileError() {
    return Column(
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Colors.amberAccent.withValues(alpha: .9),
          size: 26,
        ),
        const SizedBox(height: 8),
        Text(
          'Could not load your profile. Your saved settings are safe.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(() => _profileRevision++),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  /// Turns a save failure into a message that names the real cause instead of
  /// always blaming the connection.
  String _describeSaveError(Object error) {
    if (error is InvalidDisplayNameException) return error.message;
    if (error is ProfileUpdateRequiresSignInException) {
      return 'Sign in again to save your profile.';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Saving is blocked for this account. Check that the app has been '
              'given write access to profiles.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'No connection to the server. Your changes were not saved.';
        default:
          return 'Could not save your profile (${error.code}).';
      }
    }
    return 'Could not save your profile. Your changes were not saved.';
  }

  /// Live validation message for the display name field, or null when valid.
  String? get _nameError {
    final String value = _name.text.trim();
    if (value.isEmpty) return 'Enter a display name.';
    if (value.length > kMaxDisplayNameLength) {
      return 'Display names can be at most $kMaxDisplayNameLength characters.';
    }
    return null;
  }

  bool get _hasUnsavedChanges =>
      _avatarId != _savedAvatarId || _name.text.trim() != _savedDisplayName;

  Widget _avatarChoices() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List<Widget>.generate(
      5,
      (index) => GestureDetector(
        onTap: () => setState(() {
          _avatarId = index;
          _saveSucceeded = false;
        }),
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
    String? errorText,
    ValueChanged<String>? onChanged,
  }) => TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    onSubmitted: onSubmitted,
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.amberAccent, fontSize: 11.5),
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
