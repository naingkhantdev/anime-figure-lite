/// Where a shop stands with its subscription. The super admin controls this
/// only through `shops/{id}.expires_at`; firestore.rules make a shop
/// read-only once that time has passed.
enum ShopStatus {
  /// Signed up, waiting for the super admin to set an expiry date.
  pending,
  active,

  /// Still active, but [expiringSoonDays] or fewer days left.
  expiringSoon,
  expired;

  bool get canWrite => this == active || this == expiringSoon;
}

const expiringSoonDays = 7;

ShopStatus shopStatus(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return ShopStatus.pending;
  if (!expiresAt.isAfter(now)) return ShopStatus.expired;
  if (expiresAt.difference(now) <= const Duration(days: expiringSoonDays)) {
    return ShopStatus.expiringSoon;
  }
  return ShopStatus.active;
}

/// Whole days left, rounding a part day up, so "1 day left" shows until the
/// very end. Never negative.
int daysLeft(DateTime expiresAt, DateTime now) {
  final diff = expiresAt.difference(now);
  if (diff <= Duration.zero) return 0;
  final days = diff.inDays;
  return diff > Duration(days: days) ? days + 1 : days;
}

/// The new expiry after adding [months]. A shop that still has time left
/// keeps it; a pending or expired one starts counting from [now]. Days that
/// don't exist in the target month clamp to its last day (31 Jan + 1 = 28 Feb).
DateTime extendExpiry(DateTime? current, DateTime now, int months) {
  final from = current != null && current.isAfter(now) ? current : now;
  final monthIndex = from.month - 1 + months;
  final year = from.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, from.day > lastDay ? lastDay : from.day,
      from.hour, from.minute);
}
