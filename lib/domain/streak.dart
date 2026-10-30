/// Denní série (jako plamínek v Duolingu): kolik dní v řadě hráč uhodl aspoň jeden rébus.
/// Den se zapisuje jako `yyyy-MM-dd` v místním čase zařízení.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

DateTime? _parse(String? day) => day == null ? null : DateTime.tryParse(day);

/// Rozdíl ve dnech mezi dvěma klíči dne (kalendářní, nezávislý na letním čase).
int _daysBetween(String from, String to) {
  final a = _parse(from)!, b = _parse(to)!;
  return DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
}

/// Série po uhodnutí rébusu dnes: dnes už uhodnuto = beze změny, včera = +1, jinak začíná od 1.
int streakAfterSolve({required int streak, required String? lastDay, required DateTime now}) {
  final today = dayKey(now);
  if (lastDay == null || _parse(lastDay) == null) return 1;
  final gap = _daysBetween(lastDay, today);
  if (gap <= 0) return streak < 1 ? 1 : streak;
  return gap == 1 ? streak + 1 : 1;
}

/// Série k zobrazení: platí, jen když se naposledy uhodlo dnes nebo včera
/// (dnes má hráč ještě čas ji prodloužit), jinak je přerušená = 0.
int activeStreak({required int streak, required String? lastDay, required DateTime now}) {
  if (lastDay == null || _parse(lastDay) == null) return 0;
  final gap = _daysBetween(lastDay, dayKey(now));
  return gap >= 0 && gap <= 1 ? streak : 0;
}

/// Dnes už hráč uhodl (plamínek svítí naplno).
bool solvedToday({required String? lastDay, required DateTime now}) =>
    lastDay == dayKey(now);
