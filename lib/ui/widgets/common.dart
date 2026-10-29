import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/l10n.dart';
import '../../logic/subscription.dart';
import '../../models/shop.dart';
import '../../utils/dates.dart';
import '../theme.dart';
import 'glass.dart';
import 'skeleton.dart';

/// A message a person can act on, for any error the app's code may throw,
/// in the app's language.
String friendlyError(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is AppException) return error.message(l);
  // Before FirebaseException, which it extends.
  if (error is FirebaseAuthException) return error.message ?? error.code;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => l.errNotAllowed,
      'unavailable' => l.errOffline,
      _ => error.message ?? error.code,
    };
  }
  return error.toString();
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// A skeleton of what is coming, error text, or [data], for a Riverpod
/// [AsyncValue].
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.data,
    this.loading = const SkeletonList(),
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading,
      error: (e, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: context.l10n.couldNotLoad,
        message: friendlyError(context, e),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.secondary,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// The one thing to do next, under the message.
  final Widget? action;

  /// A quieter way out, under [action].
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Halo(icon: icon),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.inkMuted, height: 1.45)),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: action!,
              ),
            ],
            if (secondary != null) ...[
              const SizedBox(height: 6),
              secondary!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The empty state's mark: the icon on a glass disc, inside two faint rings
/// of the aurora's pink, so an empty screen still feels made.
class _Halo extends StatelessWidget {
  const _Halo({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Widget ring(double size, double alpha) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.glow.withOpacity(alpha),
              AppColors.glow.withOpacity(0),
            ]),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
        );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 132,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ring(132, 0.07),
            ring(104, 0.1),
            Glass(
              radius: 40,
              child: SizedBox.square(
                dimension: 80,
                child: Icon(icon, size: 34, color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top of a tab that has nothing of the shopper's to show yet: a plain
/// headline and one line under it, left-aligned with the page title. No
/// picture; the words say it. What to do next follows in the page.
class PageIntro extends StatelessWidget {
  const PageIntro({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 8),
        Text(message,
            style: const TextStyle(
                color: AppColors.inkMuted, fontSize: 15, height: 1.45)),
      ],
    );
  }
}

/// A heading over a group further down a page, like "In stock now".
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
    );
  }
}

/// Keeps a page's own content to a readable column on tablets, against
/// the start edge like the page title. Full width on phones.
class StartColumn extends StatelessWidget {
  const StartColumn({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A small coloured pill: a tint background, its border, and readable ink.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.soft,
    required this.line,
    required this.ink,
  });

  const Pill.success(this.label, {super.key})
      : soft = AppColors.successSoft,
        line = AppColors.successLine,
        ink = AppColors.successInk;
  const Pill.warn(this.label, {super.key})
      : soft = AppColors.warnSoft,
        line = AppColors.warnLine,
        ink = AppColors.warnInk;
  const Pill.danger(this.label, {super.key})
      : soft = AppColors.dangerSoft,
        line = AppColors.dangerLine,
        ink = AppColors.dangerInk;
  const Pill.info(this.label, {super.key})
      : soft = AppColors.infoSoft,
        line = AppColors.infoLine,
        ink = AppColors.infoInk;

  final String label;
  final Color soft;
  final Color line;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: soft,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: ink, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
      ),
    );
  }
}

class ShopStatusPill extends StatelessWidget {
  const ShopStatusPill({super.key, required this.shop, required this.now});

  final Shop shop;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (shop.statusAt(now)) {
      ShopStatus.pending => Pill.info(l.shopStatusWaiting),
      ShopStatus.active => Pill.success(l.shopStatusActive),
      ShopStatus.expiringSoon =>
        Pill.warn(l.shopDaysLeftShort(daysLeft(shop.expiresAt!, now))),
      ShopStatus.expired => Pill.danger(l.shopStatusExpired),
    };
  }
}

/// Warns the shop owner when time is running out, and explains read-only
/// mode once it has. Nothing while comfortably active.
class ExpiryBanner extends StatelessWidget {
  const ExpiryBanner({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = shop.statusAt(now);
    if (status == ShopStatus.active || status == ShopStatus.pending) {
      return const SizedBox.shrink();
    }
    final expired = status == ShopStatus.expired;
    final days = daysLeft(shop.expiresAt!, now);
    final contact = supportContact.isEmpty ? '' : ' $supportContact';
    final date = formatDate(shop.expiresAt!);
    final text = (expired
            ? context.l10n.shopExpiredBanner(date)
            : context.l10n.shopExpiresBanner(days, date)) +
        contact;
    return Material(
      color: (expired ? AppColors.dangerSoft : AppColors.warnSoft)
          .withOpacity(0.88),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: expired ? AppColors.dangerLine : AppColors.warnLine),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Icon(expired ? Icons.lock_clock : Icons.schedule,
                size: 20,
                color: expired ? AppColors.dangerInk : AppColors.warnInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: expired ? AppColors.dangerInk : AppColors.warnInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled number on a summary card.
class Stat extends StatelessWidget {
  const Stat({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.ink,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 0.66,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSubtle,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

/// Signs out after a confirmation.
Future<void> confirmSignOut(
    BuildContext context, Future<void> Function() signOut) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.signOutQuestion),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.signOut)),
      ],
    ),
  );
  if (ok == true) await signOut();
}
