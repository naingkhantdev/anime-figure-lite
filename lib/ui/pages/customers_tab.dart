import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/effects.dart';
import '../widgets/skeleton.dart';
import '../widgets/glass.dart';
import '../widgets/common.dart';
import 'customer_form_page.dart';

class CustomersTab extends ConsumerStatefulWidget {
  const CustomersTab({super.key});

  @override
  ConsumerState<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<CustomersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AsyncBody(
      value: ref.watch(customersProvider),
      loading: const SkeletonList(header: false, round: true),
      data: (customers) {
        final q = _query.trim().toLowerCase();
        final visible = customers
            .where((c) =>
                q.isEmpty ||
                c.name.toLowerCase().contains(q) ||
                c.phone.contains(q))
            .toList();
        return ListView(
          padding: pagePadding(context, bottom: 96),
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchNameOrPhone,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            if (customers.isEmpty)
              EmptyState(
                icon: Icons.people_outline,
                title: context.l10n.noCustomersYet,
                message: context.l10n.noCustomersYetBody,
              )
            else if (visible.isEmpty)
              EmptyState(
                  icon: Icons.search_off, title: context.l10n.nothingMatches)
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, c) in visible.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      Reveal(
                        index: i,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentSoft,
                            foregroundColor: AppColors.accent,
                            child: Text(c.name.characters.first.toUpperCase()),
                          ),
                          title: Text(c.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: c.phone.isEmpty && c.address.isEmpty
                              ? null
                              : Text(
                                  [c.phone, c.address]
                                      .where((s) => s.isNotEmpty)
                                      .join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.inkMuted),
                                ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CustomerFormPage(customer: c)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
