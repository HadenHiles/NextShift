import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'Home.dart';
import 'auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = false;
  bool _createAccount = false;
  bool _passwordless = false;
  late final bool _isEmailLink;

  @override
  void initState() {
    super.initState();

    _isEmailLink = isPasswordlessSignInLink(Uri.base.toString());
    _passwordless = _isEmailLink;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Home()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _RinkPainter())),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Spacer(),
                      Image.asset('assets/images/logos/hth_logo_red.png', height: 32),
                      const SizedBox(width: 10),
                      const Text('NEXT SHIFT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 860;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(wide ? 56 : 20, 24, wide ? 56 : 20, 48),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1080),
                            child: wide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Expanded(child: _LoginStatement()),
                                      const SizedBox(width: 72),
                                      SizedBox(width: 420, child: _buildAuthPanel()),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      const _LoginStatement(compact: true),
                                      const SizedBox(height: 28),
                                      _buildAuthPanel(),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPanel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF213161A),
        border: Border.all(color: const Color(0xFF343A43)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 16))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('STEP ON THE ICE', style: TextStyle(color: Color(0xFFE55353), fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Sign in to vote', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.password), label: Text('Password')),
                  ButtonSegment(value: true, icon: Icon(Icons.mail_outline), label: Text('Email link')),
                ],
                selected: {_passwordless},
                onSelectionChanged: _isLoading ? null : (selection) => setState(() => _passwordless = selection.first),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                validator: _validateEmail,
              ),
              if (!_passwordless) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters' : null,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submitEmail,
                icon: _isLoading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_passwordless ? Icons.mark_email_read_outlined : Icons.login),
                label: Text(_emailButtonLabel),
              ),
              if (!_passwordless)
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _createAccount = !_createAccount),
                  child: Text(_createAccount ? 'Already have an account? Sign in' : 'New here? Create an account'),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR')), Expanded(child: Divider())]),
              ),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _runAuth(signInWithGoogle),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _runAuth(signInWithFacebook),
                icon: const Icon(Icons.facebook),
                label: const Text('Continue with Facebook'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _emailButtonLabel {
    if (_isEmailLink) return 'Complete email sign in';
    if (_passwordless) return 'Send sign-in link';
    return _createAccount ? 'Create account' : 'Sign in';
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    if (_passwordless) {
      if (_isEmailLink) {
        await _runAuth(
          () => completePasswordlessSignIn(email, Uri.base.toString()),
        );
      } else {
        await _runAuth(
          () => sendPasswordlessSignInLink(email),
          successMessage: 'Check your email for a secure sign-in link.',
        );
      }
      return;
    }

    await _runAuth(
      () => _createAccount ? createEmailPasswordAccount(email, _passwordController.text) : signInWithEmailPassword(email, _passwordController.text),
    );
  }

  Future<void> _runAuth(
    Future<dynamic> Function() operation, {
    String? successMessage,
  }) async {
    setState(() => _isLoading = true);
    try {
      await operation();
      if (mounted && successMessage != null) _showMessage(successMessage);
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } catch (_) {
      if (mounted) _showMessage('Sign in could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' => 'The email or password is incorrect.',
      'email-already-in-use' => 'An account already uses that email address.',
      'weak-password' => 'Choose a stronger password.',
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'account-exists-with-different-credential' => 'That email already uses another sign-in method.',
      'popup-closed-by-user' || 'cancelled-popup-request' => 'Sign in was cancelled.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      _ => 'Sign in could not be completed. Please try again.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoginStatement extends StatelessWidget {
  const _LoginStatement({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(width: 54, height: 5, color: const Color(0xFFCC3333)),
        const SizedBox(height: 18),
        Text(
          'THE COMMUNITY\nCALLS THE NEXT PLAY.',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: compact ? 42 : 64),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Vote on what Coach Jeremy should make, fix, or teach next. Your voice moves the work up the lineup.',
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFFADB5C0), height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _RinkPainter extends CustomPainter {
  const _RinkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = const Color(0x0FFFFFFF);
    final red = Paint()..color = const Color(0x16CC3333);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.12, 0, 1, size.height), line);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.54, 0, 2, size.height), red);
    line.style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width * 0.54, size.height * 0.52), 118, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
