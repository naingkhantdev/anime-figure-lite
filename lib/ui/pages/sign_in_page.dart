import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
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

/// The high kick, from the splash's poses (tool/brand_assets.py). Falls back
/// to the logo if the poses are ever rebuilt without it.
const _heroPose = 'assets/brand/poses/01.png';

/// Above this width the fighter stands beside the form instead of over it.
const _sideBySideFrom = 720.0;

/// One sign-in for everybody: customers, shop admins and the super admin.
/// RoleGate decides where they land afterwards.
///
/// The splash's navy and red neon carry on at the top, where the fighter
/// rises in once; the form sits on the app's pale ground in a sheet below
/// (beside, on wide screens).
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
    final l = context.l10n;
    final email = _email.text.trim();
    // Caught here rather than as a Firebase error, in the app's language.
    final missing = email.isEmpty
        ? l.errEmailEmpty
        : _password.text.isEmpty
            ? l.errPasswordEmpty
            : null;
    if (missing != null) {
      setState(() => _error = missing);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
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

  void _setMode(bool signUp) {
    if (_busy || signUp == _isSignUp) return;
    setState(() {
      _isSignUp = signUp;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = _form(context);
    return Scaffold(
      backgroundColor: AppColors.splash,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: LayoutBuilder(builder: (context, box) {
        if (box.maxWidth >= _sideBySideFrom) {
          return Row(
            children: [
              const Expanded(child: _Hero()),
              SizedBox(
                width: 480,
                child: _Sheet(
                  radius: const BorderRadius.horizontal(
                      left: Radius.circular(32)),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
                      child: form,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        final heroHeight = (box.maxHeight * 0.36).clamp(220.0, 330.0);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: SizedBox(height: heroHeight, child: const _Hero())),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Sheet(
                radius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 24, 20, 24 + MediaQuery.paddingOf(context).bottom),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: form,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _form(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeSwitch(
            signUp: _isSignUp,
            onChanged: _busy ? null : _setMode,
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: AppMotion.quick,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Column(
              key: ValueKey(_isSignUp),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSignUp ? l.createAnAccount : l.welcomeBack,
                  style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: -0.6),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp ? l.signUpSubtitle : l.signInSubtitle,
                  style: const TextStyle(
                      color: AppColors.inkMuted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.email,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [
              _isSignUp ? AutofillHints.newPassword : AutofillHints.password
            ],
            decoration: InputDecoration(
              labelText: l.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _showPassword ? l.hidePassword : l.showPassword,
                icon: Icon(_showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
            ),
            onSubmitted: (_) => _busy ? null : _submit(),
          ),
          // Kept in the layout when signing up, so switching doesn't make
          // the button jump.
          Align(
            alignment: Alignment.centerRight,
            child: Visibility.maintain(
              visible: !_isSignUp,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: const TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                onPressed: _busy || _isSignUp ? null : _resetPassword,
                child: Text(l.forgotPassword),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.quick,
            curve: AppMotion.settle,
            alignment: Alignment.topCenter,
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ErrorNote(_error!),
                  ),
          ),
          const SizedBox(height: 4),
          _SubmitButton(
            label: _isSignUp ? l.createAccount : l.signIn,
            busy: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// The pale ground the form sits on, rounded where it meets the navy.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.radius, required this.child});

  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: AuroraBackground(child: child),
    );
  }
}

/// The fighter on the splash's navy, in a red neon glow, over the name.
/// He rises in once as the page opens; with reduce motion he is simply
/// there.
class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final _rise = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rise.value = 1;
    } else if (!_rise.isAnimating && _rise.value == 0) {
      _rise.forward();
    }
  }

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rise = CurvedAnimation(parent: _rise, curve: AppMotion.settle);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.splash,
        gradient: RadialGradient(
          center: Alignment(0, 0.05),
          radius: 0.75,
          colors: [Color(0x59FF3B4E), Color(0x00FF3B4E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AnimatedBuilder(
                  animation: rise,
                  builder: (context, child) => Opacity(
                    opacity: rise.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 28 * (1 - rise.value)),
                      child: Transform.scale(
                          scale: 0.92 + 0.08 * rise.value, child: child),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 260, maxHeight: 260),
                    child: Image.asset(
                      _heroPose,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) => const AppLogo(size: 160),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Wordmark(size: 13, color: Colors.white, shine: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sign in | Create account, a thumb sliding between them.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.signUp, required this.onChanged});

  final bool signUp;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassEdge),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: AppMotion.settle,
            alignment: signUp ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.glassShadow,
                        offset: Offset(0, 2),
                        blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (label, value) in [
                (l.signIn, false),
                (l.createAccount, true),
              ])
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: signUp == value,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onChanged == null ? null : () => onChanged!(value),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: AppMotion.quick,
                          style: TextStyle(
                            fontFamily: AppFonts.sans,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: signUp == value
                                ? AppColors.ink
                                : AppColors.inkMuted,
                          ),
                          child: Text(label,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.dangerLine),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 20, color: AppColors.dangerInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.dangerInk, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main action: a pink pill that lifts off the sheet on a soft pink
/// shadow, with an arrow, or a spinner while it works.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          if (!busy)
            const BoxShadow(
              color: Color(0x40E0115F),
              offset: Offset(0, 10),
              blurRadius: 24,
              spreadRadius: -6,
            ),
        ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          // Stays pink while busy; the spinner says it is working.
          disabledBackgroundColor: AppColors.accent,
          disabledForegroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }
}
