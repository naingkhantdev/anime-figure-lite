/// The shop sells in Myanmar kyat (MMK), which has no minor unit in use.
/// Money is stored in Firestore as integer whole kyats (25000 = 25,000 Ks);
/// doubles must never be used for currency. Display only.
String formatMmk(int kyats) =>
    '${kyats < 0 ? '-' : ''}${groupThousands(kyats.abs())} Ks';

/// 1500000 → "1,500,000".
String groupThousands(int n) => n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
