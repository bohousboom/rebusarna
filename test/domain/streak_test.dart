import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/streak.dart';

void main() {
  final d = DateTime(2026, 10, 30, 14);

  test('první uhodnutí začíná sérii od 1', () {
    expect(streakAfterSolve(streak: 0, lastDay: null, now: d), 1);
  });
  test('další rébus ve stejný den sérii nemění', () {
    expect(streakAfterSolve(streak: 3, lastDay: '2026-10-30', now: d), 3);
  });
  test('včera uhodnuto = série roste', () {
    expect(streakAfterSolve(streak: 3, lastDay: '2026-10-29', now: d), 4);
    // přes hranici měsíce a roku
    expect(streakAfterSolve(streak: 5, lastDay: '2026-12-31', now: DateTime(2027, 1, 1)), 6);
  });
  test('vynechaný den = začíná znovu', () {
    expect(streakAfterSolve(streak: 9, lastDay: '2026-10-28', now: d), 1);
  });
  test('zobrazená série: dnes a včera platí, starší je přerušená', () {
    expect(activeStreak(streak: 4, lastDay: '2026-10-30', now: d), 4);
    expect(activeStreak(streak: 4, lastDay: '2026-10-29', now: d), 4);
    expect(activeStreak(streak: 4, lastDay: '2026-10-27', now: d), 0);
    expect(activeStreak(streak: 4, lastDay: null, now: d), 0);
  });
  test('solvedToday', () {
    expect(solvedToday(lastDay: '2026-10-30', now: d), isTrue);
    expect(solvedToday(lastDay: '2026-10-29', now: d), isFalse);
  });
}
