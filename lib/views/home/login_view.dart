import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/guest_mode_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/generated_avatar.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final UserProfileService _profiles = UserProfileService();
  final GuestModeService _guestMode = GuestModeService();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _creatingAccount = false;
  bool _working = false;
  bool _hidePassword = true;
  late int _avatarId;

  @override
  void initState() {
    super.initState();
    _avatarId = Random.secure().nextInt(5);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_creatingAccount && _name.text.trim().isEmpty) {
      _showMessage('Enter your name to create an account.');
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _showMessage('Enter your email and password.');
      return;
    }

    setState(() => _working = true);
    try {
      if (_creatingAccount) {
        await _profiles.createAccount(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          avatarId: _avatarId,
        );
      } else {
        await _profiles.signIn(email: _email.text, password: _password.text);
      }
      await _guestMode.clearGuestChoice();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _working = true);
    try {
      final UserCredential? credential = await _profiles.signInWithGoogle();
      if (credential == null) return;
      await _guestMode.clearGuestChoice();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      _showMessage('Enter your email first, then choose “Forgot password?”.');
      return;
    }
    try {
      await _profiles.sendPasswordResetEmail(_email.text);
      if (mounted) _showMessage('Password reset email sent.');
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    }
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => 'An account already uses this email.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Choose a password with at least 6 characters.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Email or password is incorrect.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'too-many-requests' =>
          'Too many attempts. Wait a little and try again.',
        _ => error.message ?? 'Could not access your account. Try again.',
      };
    }
    return 'Could not save your profile. Check your connection and try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071426),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(_creatingAccount ? 'Create account' : 'Log in'),
    ),
    body: Stack(
      children: [
        const Positioned(
          top: -100,
          right: -110,
          child: _LoginGlow(color: Color(0xFF1565C0)),
        ),
        const Positioned(
          bottom: -100,
          left: -100,
          child: _LoginGlow(color: Color(0xFF673AB7)),
        ),
        SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _panel(
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GeneratedAvatar(avatarId: _avatarId, size: 74),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _creatingAccount ? 'Join GameSet' : 'Welcome back',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            _creatingAccount
                                ? 'Create your profile and pick a game icon.'
                                : 'Log in to manage your GameSet profile.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _working ? null : _signInWithGoogle,
                            icon: const Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            label: const Text('Continue with Google'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                        if (_creatingAccount) ...[
                          const SizedBox(height: 16),
                          _input(
                            _name,
                            'Display name',
                            Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                        SizedBox(height: _creatingAccount ? 12 : 26),
                        _input(
                          _email,
                          'Email',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          _password,
                          'Password',
                          Icons.lock_outline_rounded,
                          obscureText: _hidePassword,
                          suffix: IconButton(
                            tooltip: _hidePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (!_creatingAccount)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _working ? null : _resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        if (_creatingAccount) ...[
                          const SizedBox(height: 22),
                          const Text(
                            'Choose your game icon',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _avatarChoices(),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _working ? null : _submit,
                            child: _working
                                ? const SizedBox.square(
                                    dimension: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _creatingAccount
                                        ? 'Create account'
                                        : 'Log in',
                                  ),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _working
                                ? null
                                : () => setState(
                                    () => _creatingAccount = !_creatingAccount,
                                  ),
                            child: Text(
                              _creatingAccount
                                  ? 'Already have an account? Log in'
                                  : 'New to GameSet? Create an account',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

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
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) => TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    onSubmitted: onSubmitted,
    autofillHints: label == 'Email'
        ? const [AutofillHints.email]
        : label == 'Password'
        ? [
            _creatingAccount
                ? AutofillHints.newPassword
                : AutofillHints.password,
          ]
        : const [AutofillHints.name],
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
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

  Widget _panel(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .075),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: child,
      ),
    ),
  );
}

class _LoginGlow extends StatelessWidget {
  const _LoginGlow({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 300,
    height: 300,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .13),
    ),
  );
}
