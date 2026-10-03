import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/report.dart';

Report _r(String id, ReportReason reason, int day, {String? note}) =>
    Report(puzzleId: id, reason: reason, createdAt: DateTime(2026, 1, day), note: note);

void main() {
  test('prázdný vstup', () => expect(groupReports([]), isEmpty));

  test('seskupí podle rébusu a spočítá důvody', () {
    final g = groupReports([
      _r('a', ReportReason.adult, 1),
      _r('a', ReportReason.adult, 2),
      _r('a', ReportReason.wrong, 3, note: ' chyba '),
      _r('b', ReportReason.offensive, 4),
    ]);
    expect(g.length, 2);
    final a = g.firstWhere((x) => x.puzzleId == 'a');
    expect(a.total, 3);
    expect(a.counts[ReportReason.adult], 2);
    expect(a.counts[ReportReason.wrong], 1);
    expect(a.notes, ['chyba']);
    expect(a.latest, DateTime(2026, 1, 3));
  });

  test('více nahlášené jsou první, při shodě novější', () {
    final g = groupReports([
      _r('x', ReportReason.other, 1),
      _r('y', ReportReason.other, 5),
      _r('z', ReportReason.other, 2),
      _r('z', ReportReason.other, 3),
    ]);
    expect(g.map((e) => e.puzzleId), ['z', 'y', 'x']);
  });

  test('prázdné poznámky se vynechají', () {
    final g = groupReports([_r('a', ReportReason.other, 1, note: '   ')]);
    expect(g.single.notes, isEmpty);
  });

  test('neznámý důvod z databáze = jiný', () {
    expect(ReportReason.fromId('nesmysl'), ReportReason.other);
    expect(ReportReason.fromId('adult'), ReportReason.adult);
  });
}
