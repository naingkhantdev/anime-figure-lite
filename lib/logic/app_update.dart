/// Whether the installed app should be updated. The app is installed from
/// a downloaded APK, not the Play Store, so nothing updates it by itself.
enum UpdateNeed {
  none,

  /// A newer build is out: offer it, but let the person carry on.
  available,

  /// This build is older than the oldest still allowed: block until updated.
  required,
}

/// What `app_config/android` says. Builds are the number after the `+` in
/// pubspec.yaml's `version` (Android's versionCode).
class AppRelease {
  const AppRelease({
    required this.latestBuild,
    required this.minBuild,
    required this.apkUrl,
  });

  final int latestBuild;
  final int minBuild;
  final String apkUrl;

  UpdateNeed needFor(int installedBuild) {
    if (apkUrl.isEmpty) return UpdateNeed.none;
    if (installedBuild < minBuild) return UpdateNeed.required;
    if (installedBuild < latestBuild) return UpdateNeed.available;
    return UpdateNeed.none;
  }
}
