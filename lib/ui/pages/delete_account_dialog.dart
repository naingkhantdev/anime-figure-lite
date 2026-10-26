import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
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
        title: const Text('Delete my account'),
        content: Text(
          'Your account holds your shop and its stock history, so we close '
          'it for you. Contact us to close your shop and delete your '
          'account${supportContact.isEmpty ? '.' : ': $supportContact'}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
    try {
      // Password first, so a typo stops here before anything is wiped.
      await auth.confirmPassword(_password.text);
      await ref
          .read(orderRepositoryProvider)
          .forgetContactDetails(auth.currentUser!.uid);
      await auth.deleteAccount();
      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Your account has been deleted.')));
    } on FirebaseAuthException catch (e) {
      final wrong =
          e.code == 'wrong-password' || e.code == 'invalid-credential';
      if (mounted) {
        setState(() => _error = wrong ? 'Wrong password.' : friendlyError(e));
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete my account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This cannot be undone. Pending orders are cancelled. Past orders '
            'stay with the shop, without your phone number or address.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Your password'),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.dangerInk),
          onPressed: _busy ? null : _delete,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
