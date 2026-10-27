import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';

/// Returns true if a user is signed in, opening [SignInPage] first when
/// nobody is (on "Create an account" with [signUp]). Returns false if the
/// user backs out without signing in.
Future<bool> ensureSignedIn(BuildContext context, WidgetRef ref,
    {bool signUp = false}) async {
  if (ref.read(authRepositoryProvider).currentUser != null) return true;
  final signedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => SignInPage(signUp: signUp)),
  );
  return signedIn ?? false;
}

/// One sign-in for everybody: customers, shop admins and the super admin.
/// RoleGate decides where they land afterwards.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key, this.signUp = false});

  /// Open on "Create an account" rather than "Welcome back".
  final bool signUp;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _isSignUp = widget.signUp;
  bool _showPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    try {
      if (_isSignUp) {
        await auth.signUp(email, _password.text);
      } else {
        await auth.signIn(email, _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = context.l10n.typeEmailFirst);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) showMessage(context, context.l10n.passwordResetSent(email));
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BrandHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: BorderBeam(
                  radius: AppRadius.xxl,
                  child: Glass(
                    radius: AppRadius.xxl,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSwitcher(
                            duration: AppMotion.quick,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                            child: Text(
                              _isSignUp
                                  ? context.l10n.createAnAccount
                                  : context.l10n.welcomeBack,
                              key: ValueKey(_isSignUp),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSignUp
                                ? context.l10n.signUpSubtitle
                                : context.l10n.signInSubtitle,
                            style: const TextStyle(color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                                labelText: context.l10n.email),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: !_showPassword,
                            autofillHints: [
                              _isSignUp
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password
                            ],
                            decoration: InputDecoration(
                              labelText: context.l10n.password,
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? context.l10n.hidePassword
                                    : context.l10n.showPassword,
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                              ),
                            ),
                            onSubmitted: (_) => _busy ? null : _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.dangerInk)),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_isSignUp
                                    ? context.l10n.createAccount
                                    : context.l10n.signIn),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _isSignUp = !_isSignUp;
                                      _error = null;
                                    }),
                            child: Text(_isSignUp
                                ? context.l10n.haveAccountSignIn
                                : context.l10n.newHereCreateAccount),
                          ),
                          if (!_isSignUp)
                            TextButton(
                              onPressed: _busy ? null : _resetPassword,
                              child: Text(context.l10n.forgotPassword),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
