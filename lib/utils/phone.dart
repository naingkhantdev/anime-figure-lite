/// Removes spaces and dashes, then accepts Myanmar mobile numbers written as
/// `09…` or `+959…`. Deliberately loose so real numbers are never rejected.
/// Returns the cleaned number, or null if it doesn't look like a phone.
String? normalizePhone(String input) {
  final phone = input.replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^(09|\+959)\d{7,9}$').hasMatch(phone) ? phone : null;
}
