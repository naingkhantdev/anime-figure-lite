/// Money is stored as integer cents in Firestore (Firestore has no decimal
/// type, and doubles must never be used for currency). Display only.
String formatCents(int cents) {
  final whole = (cents ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return '$whole.$fraction';
}
