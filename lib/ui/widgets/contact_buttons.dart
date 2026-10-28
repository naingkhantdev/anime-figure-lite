import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../utils/phone.dart';
import 'common.dart';

/// Call and Viber buttons for [phone]. Orders are settled by phone, so
/// these sit on each order, for the shop and for the customer.
class ContactButtons extends StatelessWidget {
  const ContactButtons({super.key, required this.phone});

  final String phone;

  /// Opens the dialer on [phone]. False if the device can't place calls.
  static Future<bool> call(String phone) async {
    try {
      return await launchUrl(
          Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
    } catch (_) {
      return false;
    }
  }

  /// Opens a Viber chat; when Viber isn't on the phone, says so and offers
  /// a call instead.
  static Future<void> viber(BuildContext context, String phone) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(
        'viber://chat?number=${Uri.encodeComponent(internationalPhone(phone))}');
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No app takes viber:// links.
    }
    if (opened) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.viberNotInstalled),
        action: SnackBarAction(label: l.call, onPressed: () => call(phone)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              if (!await call(phone) && context.mounted) {
                showMessage(context, l.cannotCall(phone));
              }
            },
            icon: const Icon(Icons.call_outlined, size: 18),
            label: Text(l.call),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => viber(context, phone),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Viber'),
          ),
        ),
      ],
    );
  }
}
