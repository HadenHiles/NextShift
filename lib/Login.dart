import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'Home.dart';
import 'auth.dart';
import 'widgets/Heading.dart';

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
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.sports_hockey, size: 44),
                    const SizedBox(height: 12),
                    const Heading(text: 'Join the next shift', size: 40),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to vote and tell Coach Jeremy what the hockey community needs next.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFADB5C0), fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.password),
                          label: Text('Password'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.mail_outline),
                          label: Text('Email link'),
                        ),
                      ],
                      selected: {_passwordless},
                      onSelectionChanged: _isLoading
                          ? null
                          : (selection) {
                              setState(() => _passwordless = selection.first);
                            },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    if (!_passwordless) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Use at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submitEmail,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_passwordless ? Icons.mark_email_read_outlined : Icons.login),
                      label: Text(_emailButtonLabel),
                    ),
                    if (!_passwordless)
                      TextButton(
                        onPressed: _isLoading ? null : () => setState(() => _createAccount = !_createAccount),
                        child: Text(
                          _createAccount ? 'Already have an account? Sign in' : 'New here? Create an account',
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
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
