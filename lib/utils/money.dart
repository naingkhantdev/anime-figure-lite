/// The shop sells in Myanmar kyat (MMK), which has no minor unit in use.
/// Money is stored in Firestore as integer whole kyats (25000 = 25,000 Ks);
/// doubles must never be used for currency. Display only.
String formatMmk(int kyats) {
  final digits = kyats.abs().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
  return '${kyats < 0 ? '-' : ''}$digits Ks';
}
