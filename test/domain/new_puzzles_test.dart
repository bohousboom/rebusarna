import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/models/puzzle.dart';
import 'package:rebusarna/domain/models/word_type.dart';
import 'package:rebusarna/domain/new_puzzles.dart';

final _now = DateTime(2026, 10, 14);

Puzzle _p(String id, {String? owner = 'u1', int daysAgo = 1}) => Puzzle(
      id: id,
      image: 'x',
      solution: id,
      wordTypes: [WordType.noun],
      difficulty: 1,
      authorName: 't',
      ownerId: owner,
      createdAt: _now.subtract(Duration(days: daysAgo)),
    );

void main() {
  test('jen cizí uživatelské karty za 7 dní, nejnovější první', () {
    final all = [
      _p('old', daysAgo: 10),
      _p('a', daysAgo: 3),
      _p('b', daysAgo: 1),
      _p('mine', owner: 'admin'),
      _p('seed-x'),
      _p('builtin', owner: null),
    ];
    final r = recentUserPuzzles(all, now: _now, excludeOwnerId: 'admin');
    expect(r.map((p) => p.id), ['b', 'a']);
  });
}
