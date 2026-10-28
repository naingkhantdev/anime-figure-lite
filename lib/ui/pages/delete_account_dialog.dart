import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Google Play and the App Store require that an account made in the app can
/// be deleted from it. Customers delete straight away; their orders stay,
/// without phone, address or note.
Future<void> showDeleteAccountDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

/// A shop owner's account holds the shop's stock history, so it is closed by
/// the super admin rather than deleted from the phone by accident.
Future<void> showCloseShopDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteMyAccount),
        content: Text(supportContact.isEmpty
            ? context.l10n.closeShopBody
            : context.l10n.closeShopBodyContact(supportContact)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final deleted = context.l10n.accountDeleted;
    try {
      // Password first, so a typo stops here before anything is wiped.
      await auth.confirmPassword(_password.text);
      await ref
          .read(orderRepositoryProvider)
          .forgetContactDetails(auth.currentUser!.uid);
      // Off the super admin's list; never a reason to keep the account.
      await ref
          .read(userRepositoryProvider)
          .forget(auth.currentUser!.uid)
          .catchError((Object e) => debugPrint('Could not forget user: $e'));
      await auth.deleteAccount();
      navigator.pop();
      messenger.showSnackBar(
          SnackBar(content: Text(deleted)));
    } on FirebaseAuthException catch (e) {
      final wrong =
          e.code == 'wrong-password' || e.code == 'invalid-credential';
      if (mounted) {
        setState(() => _error =
            wrong ? context.l10n.wrongPassword : friendlyError(context, e));
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.deleteMyAccountQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.deleteAccountBody),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: context.l10n.yourPassword),
            onSubmitted: (_) => _busy ? null : _delete(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.dangerInk)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.dangerInk),
          onPressed: _busy ? null : _delete,
          child: Text(context.l10n.delete),
        ),
      ],
    );
  }
}
