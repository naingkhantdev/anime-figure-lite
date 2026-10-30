import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import '../l10n/app_localizations.dart';
import '../logic/order_alerts.dart';
import '../providers/providers.dart' show languageKey;

/// Tells a shop admin about new orders. The Spark plan has no server to
/// send push messages, so the phone looks for itself:
///
/// - while the app runs, ShopHomePage hands every change of the shop's
///   orders to [alertNew];
/// - while it doesn't, Android runs [orderCheckDispatcher] about every 15
///   minutes, which asks Firestore for the shop's waiting orders.
///
/// Both share the ids already alerted (SharedPreferences), so an order is
/// announced once. Battery savers (Xiaomi, Oppo, Vivo…) may delay or skip
/// the background check; ShopHomePage tells the shop once how to stop that.
class OrderAlerts {
  static const _task = 'order-check';
  static const _channelId = 'orders';
  static const _notificationId = 1;

  /// Whose shop the background check is for: the uid at [start].
  static const _alertsForKey = 'order_alerts_for';
  static const _alertedKey = 'order_alerts_alerted';
  static const _batteryTipKey = 'order_alerts_battery_tip_shown';

  /// What a tap on the notification sends back.
  static const payload = 'orders';

  final _plugin = FlutterLocalNotificationsPlugin();

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Sets up notifications for shop [uid] and starts the background check.
  /// [onTap] runs when a notification is tapped while the app is running.
  /// True if the app was just opened by tapping one. Never throws.
  Future<bool> start(String uid, {required void Function() onTap}) async {
    if (!_supported) return false;
    try {
      await _init(_plugin, onTap: onTap);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alertsForKey, uid);
      await Workmanager().initialize(orderCheckDispatcher);
      await Workmanager().registerPeriodicTask(
        _task,
        _task,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      return launch?.didNotificationLaunchApp == true &&
          launch?.notificationResponse?.payload == payload;
    } catch (e) {
      debugPrint('Order alerts did not start: $e');
      return false;
    }
  }

  /// Stops the background check, at sign-out. Never throws.
  Future<void> stop() async {
    if (!_supported) return;
    try {
      await Workmanager().cancelByUniqueName(_task);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_alertsForKey);
      await prefs.remove(_alertedKey);
    } catch (e) {
      debugPrint('Order alerts did not stop: $e');
    }
  }

  /// The shop's waiting orders are now [pendingIds]: remembers them, and
  /// with [notify] announces those not announced before. Never throws.
  Future<void> alertNew(List<String> pendingIds, AppLocalizations l,
      {required bool notify}) async {
    if (!_supported) return;
    try {
      final count = await _remember(pendingIds);
      if (notify && count > 0) await _show(_plugin, l, count);
    } catch (e) {
      debugPrint('Order alert failed: $e');
    }
  }

  /// True the first time only: whether to tell the shop about battery
  /// savers. Never throws.
  Future<bool> takeBatteryTip() async {
    if (!_supported) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_batteryTipKey) == true) return false;
      await prefs.setBool(_batteryTipKey, true);
      return true;
    } catch (_) {
      return false;
    }
  }
}

Future<void> _init(FlutterLocalNotificationsPlugin plugin,
    {void Function()? onTap}) async {
  await plugin.initialize(
    const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification')),
    onDidReceiveNotificationResponse: (response) {
      if (response.payload == OrderAlerts.payload) onTap?.call();
    },
  );
}

/// Stores [pendingIds] as announced; returns how many were not before.
/// Reloads first: the app and the background check each have a copy.
Future<int> _remember(List<String> pendingIds) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final alerted = (prefs.getStringList(OrderAlerts._alertedKey) ?? []).toSet();
  final fresh = newOrderIds(pendingIds, alerted);
  await prefs.setStringList(OrderAlerts._alertedKey, pendingIds);
  return fresh.length;
}

Future<void> _show(FlutterLocalNotificationsPlugin plugin, AppLocalizations l,
        int count) =>
    plugin.show(
      OrderAlerts._notificationId,
      l.newOrdersTitle(count),
      l.newOrdersBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          OrderAlerts._channelId,
          l.ordersChannel,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
        ),
      ),
      payload: OrderAlerts.payload,
    );

/// The background check, run by Android in its own isolate about every 15
/// minutes while the app is closed. Reads only the shop's waiting orders.
@pragma('vm:entry-point')
void orderCheckDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      final user = await FirebaseAuth.instance.authStateChanges().first;
      final prefs = await SharedPreferences.getInstance();
      // Signed out, or someone else signed in since: nothing to check.
      if (user == null ||
          prefs.getString(OrderAlerts._alertsForKey) != user.uid) {
        return true;
      }
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('shop_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get(const GetOptions(source: Source.server));
      final count = await _remember(snap.docs.map((d) => d.id).toList());
      if (count > 0) {
        final plugin = FlutterLocalNotificationsPlugin();
        await _init(plugin);
        await _show(plugin, _backgroundLocalizations(prefs), count);
      }
    } catch (e) {
      debugPrint('Order check failed: $e');
    }
    // Always "done": a failed check waits for the next one, not a retry.
    return true;
  });
}

/// The app's language with no BuildContext: the one picked in the app
/// ([languageKey]), else the phone's when the app has it, else English.
AppLocalizations _backgroundLocalizations(SharedPreferences prefs) {
  final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode);
  final phone = PlatformDispatcher.instance.locale.languageCode;
  final code =
      prefs.getString(languageKey) ?? (codes.contains(phone) ? phone : 'en');
  return lookupAppLocalizations(Locale(code));
}
