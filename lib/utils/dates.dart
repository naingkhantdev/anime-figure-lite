// Hand-rolled so the app doesn't need the intl package for two formats.
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `5 Mar 2026`
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// `5 Mar 2026, 09:07`
String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatTime(d)}';

/// `09:07`
String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String _two(int n) => n.toString().padLeft(2, '0');

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
