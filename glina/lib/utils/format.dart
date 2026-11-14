String formatMoney(int value, {bool sign = false}) {
  final abs = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buf.write(' ');
    buf.write(abs[i]);
  }
  final prefix = value < 0 ? '−' : (sign && value > 0 ? '+' : '');
  return '$prefix$buf ₸';
}

const _shortMonths = [
  'янв.',
  'февр.',
  'мар.',
  'апр.',
  'мая',
  'июн.',
  'июл.',
  'авг.',
  'сент.',
  'окт.',
  'нояб.',
  'дек.',
];

const _shortWeekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

String weekdayShort(DateTime d) => _shortWeekdays[d.weekday - 1];

String formatShortDate(DateTime d, {required DateTime now}) {
  final base = '${d.day} ${_shortMonths[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}

String formatDayHeader(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime.utc(n.year, n.month, n.day);
  final day = DateTime.utc(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Сегодня';
  if (diff == 1) return 'Вчера';
  return '${weekdayShort(d)}, ${formatShortDate(d, now: n)}';
}

String formatRangeLabel(DateTime start, DateTime end, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final a = formatShortDate(start, now: n);
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return a;
  }
  return '$a – ${formatShortDate(end, now: n)}';
}

const monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const _monthsNom = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

String formatDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Сегодня';
  if (diff == 1) return 'Вчера';
  final base = '${d.day} ${monthsGenitive[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}

String formatMonth(DateTime d) {
  final name = _monthsNom[d.month - 1];
  return d.year == DateTime.now().year ? name : '$name ${d.year}';
}
