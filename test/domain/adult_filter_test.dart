import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/adult_filter.dart';
import 'package:rebusarna/domain/models/puzzle.dart';
import 'package:rebusarna/domain/models/word_type.dart';

Puzzle _p(String id, {bool adult = false, bool hidden = false}) => Puzzle(
      id: id,
      image: 'assets/images/x.webp',
      solution: id,
      wordTypes: [WordType.noun],
      difficulty: 1,
      authorName: 't',
      createdAt: DateTime(2026),
      adult: adult,
      hidden: hidden,
    );

void main() {
  final all = [_p('a'), _p('b', adult: true), _p('c')];

  test('bez zapnutí se 18+ skryje', () {
    expect(visiblePuzzles(all, showAdult: false).map((p) => p.id), ['a', 'c']);
  });

  test('po zapnutí se zobrazí vše', () {
    expect(visiblePuzzles(all, showAdult: true).map((p) => p.id), ['a', 'b', 'c']);
  });

  test('automaticky skryté se nehrají ani s 18+', () {
    final l = [_p('a'), _p('h', hidden: true)];
    expect(visiblePuzzles(l, showAdult: true).map((p) => p.id), ['a']);
  });

  test('JSON zachová značku 18+ a výchozí je false', () {
    expect(Puzzle.fromJson(_p('b', adult: true).toJson()).adult, isTrue);
    expect(Puzzle.fromJson(_p('a').toJson()).adult, isFalse);
    expect(_p('a').toJson().containsKey('adult'), isFalse);
  });
}
