import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../models/shop_public.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import 'common.dart';
import 'glass.dart';

/// A shop's ways to pay, each with a button that copies its number.
class PaymentMethodsList extends StatelessWidget {
  const PaymentMethodsList({super.key, required this.methods});

  final List<PaymentMethod> methods;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        for (final m in methods)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Glass(
              radius: AppRadius.md,
              shadow: false,
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.type.label(l),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(m.accountName,
                            style: const TextStyle(color: AppColors.inkMuted)),
                        SelectableText(m.number,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.copy,
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: m.number));
                      if (context.mounted) {
                        showMessage(context, l.copied(m.number));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows a payment screenshot full size, pinch to zoom.
Future<void> showPaymentProof(BuildContext context, String proofId) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(16),
        child: Consumer(
          builder: (context, ref, _) => ref
              .watch(paymentProofProvider(proofId))
              .when(
                data: (bytes) => bytes == null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.screenshotGone),
                      )
                    : InteractiveViewer(
                        maxScale: 5,
                        child: Image.memory(bytes, fit: BoxFit.contain),
                      ),
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(friendlyError(context, e)),
                ),
              ),
        ),
      ),
    );
