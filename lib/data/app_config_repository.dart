import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../logic/app_update.dart';

/// Firestore: `app_config/android`, edited by hand in the Firebase console
/// at each release (see README "Releasing an update").
/// Fields: latest_version (int), min_version (int), apk_url (string).
class AppConfigRepository {
  AppConfigRepository(this._db);

  final FirebaseFirestore _db;

  /// What the installed app should do, and where the new APK is; read once
  /// per start (one document read). Never blocks on a failure: offline, a
  /// missing document or any other phone than Android means no update.
  Future<({UpdateNeed need, String apkUrl})> updateCheck() async {
    const none = (need: UpdateNeed.none, apkUrl: '');
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return none;
    try {
      final info = await PackageInfo.fromPlatform();
      final installed = int.tryParse(info.buildNumber);
      final release = await latestRelease();
      if (installed == null || release == null) return none;
      return (need: release.needFor(installed), apkUrl: release.apkUrl);
    } catch (_) {
      return none;
    }
  }

  Future<AppRelease?> latestRelease() async {
    final data =
        (await _db.collection('app_config').doc('android').get()).data();
    if (data == null) return null;
    return AppRelease(
      latestBuild: (data['latest_version'] as num?)?.toInt() ?? 0,
      minBuild: (data['min_version'] as num?)?.toInt() ?? 0,
      apkUrl: data['apk_url'] as String? ?? '',
    );
  }
}
