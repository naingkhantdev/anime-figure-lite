import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/providers/providers.dart';
import 'package:anime_figure_shop_lite/ui/pages/customer_home_page.dart';

class FakeUser implements User {
  FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('signing in keeps the tab; signing out goes back to Shop', () async {
    final auth = StreamController<User?>();
    addTearDown(auth.close);
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith((ref) => auth.stream),
    ]);
    addTearDown(container.dispose);
    container.listen(customerTabProvider, (_, __) {});
    final tabs = container.read(customerTabProvider.notifier);

    Future<void> emit(User? user) async {
      auth.add(user);
      await container.read(authStateProvider.future);
      await Future<void>.delayed(Duration.zero);
    }

    await emit(null);
    tabs.state = CustomerTab.account;
    await emit(FakeUser('a'));
    expect(tabs.state, CustomerTab.account);

    await emit(null);
    expect(tabs.state, CustomerTab.shop);
  });
}
