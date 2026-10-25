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

  /// Inline validation messages, cleared as the user types.
  String? _nameError;
  String? _emailError;
  String? _passwordError;

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
    final bool valid = _validate();
    if (!valid) return;

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
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// Validates every visible field and paints messages inline.
  /// Returns true when the form may be submitted.
  bool _validate() {
    final String email = _email.text.trim();
    final String password = _password.text;

    final String? nameError = _creatingAccount
        ? (_name.text.trim().isEmpty
              ? 'Enter a display name.'
              : _name.text.trim().length > kMaxDisplayNameLength
              ? 'Use at most $kMaxDisplayNameLength characters.'
              : null)
        : null;

    final String? emailError = email.isEmpty
        ? 'Enter your email address.'
        : !_looksLikeEmail(email)
        ? 'That does not look like an email address.'
        : null;

    final String? passwordError = password.isEmpty
        ? 'Enter a password.'
        : (_creatingAccount && password.length < 6)
        ? 'Use at least 6 characters.'
        : null;

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
    });
    return nameError == null && emailError == null && passwordError == null;
  }

  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  /// Switches between Log in and Create account, clearing stale errors.
  void _setCreatingAccount({required bool creating}) {
    setState(() {
      _creatingAccount = creating;
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });
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
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firebase denied access to this profile. Check the deployed Firestore rules for this account.';
      }
      return 'Firebase could not save the profile (${error.code}). ${error.message ?? 'Check the Firebase project and connection.'}';
    }
    return 'Could not complete the account request (${error.runtimeType}): $error';
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
                        if (_creatingAccount) ...[
                          const SizedBox(height: 16),
                          _input(
                            _name,
                            'Display name',
                            Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            errorText: _nameError,
                            onChanged: (_) => setState(() => _nameError = null),
                          ),
                        ],
                        SizedBox(height: _creatingAccount ? 12 : 26),
                        _input(
                          _email,
                          'Email',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: (_) => setState(() => _emailError = null),
                        ),
                        const SizedBox(height: 12),
                        _input(
                          _password,
                          'Password',
                          Icons.lock_outline_rounded,
                          obscureText: _hidePassword,
                          errorText: _passwordError,
                          onChanged: (_) =>
                              setState(() => _passwordError = null),
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
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              _selectedIconLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .55),
                                fontSize: 12,
                              ),
                            ),
                          ),
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
                                : () => _setCreatingAccount(
                                    creating: !_creatingAccount,
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

  static const List<String> _iconNames = [
    'Controller',
    'Rocket',
    'Robot',
    'Bolt',
    'Shield',
  ];

  String get _selectedIconLabel =>
      'Selected icon: ${_iconNames[_avatarId.clamp(0, 4)]}';

  Widget _avatarChoices() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List<Widget>.generate(
      5,
      (index) => GestureDetector(
        onTap: () => setState(() {
          _avatarId = index;
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
    Widget? suffix,
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
