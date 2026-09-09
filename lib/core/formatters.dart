const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const _weekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// "12 Eylül 2026"
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// "Cuma, 12 Eylül"
String formatDayMonth(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

/// "14:30"
String formatTime(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

/// "12 Eylül 2026, 14:30"
String formatDateTime(DateTime date) =>
    '${formatDate(date)}, ${formatTime(date)}';

/// "20 dk önce", "3 saat önce", "2 gün önce"
String formatRelative(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.isNegative) return formatDate(date);
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} saat önce';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  return formatDate(date);
}

/// 1450 -> "1.450 ₺"
String formatPrice(double value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  final sign = rounded < 0 ? '-' : '';
  return '$sign$buffer ₺';
}
