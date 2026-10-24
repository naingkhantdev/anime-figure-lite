import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../utils/money.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No orders yet.'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final order = list[i];
                  final date = order.createdAt?.toLocal();
                  final itemCount =
                      order.items.fold<int>(0, (s, l) => s + l.quantity);
                  return ListTile(
                    title: Text(formatCents(order.totalCents)),
                    subtitle: Text(
                      '$itemCount item(s)'
                      '${date == null ? '' : ' · ${date.year}-${_two(date.month)}-${_two(date.day)}'}',
                    ),
                    trailing: Chip(label: Text(order.status)),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load orders.\n$e')),
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
