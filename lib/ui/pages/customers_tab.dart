import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../theme.dart';
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
      data: (customers) {
        final q = _query.trim().toLowerCase();
        final visible = customers
            .where((c) =>
                q.isEmpty ||
                c.name.toLowerCase().contains(q) ||
                c.phone.contains(q))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or phone',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            if (customers.isEmpty)
              const EmptyState(
                icon: Icons.people_outline,
                title: 'No customers yet',
                message: 'Add regulars here, then pick them when you record '
                    'a stock out.',
              )
            else if (visible.isEmpty)
              const EmptyState(icon: Icons.search_off, title: 'Nothing matches')
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, c) in visible.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceSunken,
                          foregroundColor: AppColors.ink,
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
                                style:
                                    const TextStyle(color: AppColors.inkMuted),
                              ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CustomerFormPage(customer: c)),
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
