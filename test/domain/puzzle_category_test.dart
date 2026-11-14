import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/models/puzzle.dart';
import 'package:rebusarna/domain/models/puzzle_category.dart';

void main() {
  test('Ostatní není informativní, ostatní základní sady ano', () {
    expect(PuzzleCategory.other.isInformative, isFalse);
    expect(PuzzleCategory.builtIn.where((c) => c.isInformative).length,
        PuzzleCategory.builtIn.length - 1);
  });

  test('id sad jsou jedinečná a ve tvaru, který povolí databáze', () {
    final ids = [for (final c in PuzzleCategory.builtIn) c.id];
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(RegExp(r'^[a-z0-9_]+$').hasMatch(id), isTrue, reason: id);
    }
  });

  test('id z názvu nové sady: bez diakritiky a mezer', () {
    expect(PuzzleCategory.idFromLabel('Jídlo a pití'), 'jidlo_a_piti');
    expect(PuzzleCategory.idFromLabel('  Žluťoučký kůň! '), 'zlutoucky_kun');
    expect(PuzzleCategory.idFromLabel('???'), '');
  });

  test('sada se uloží a načte z JSON; Ostatní se neukládá', () {
    final p = Puzzle(
      id: 'a',
      image: 'assets/images/a.webp',
      solution: 'Ananas',
      wordTypes: const [],
      difficulty: 1,
      authorName: 'x',
      createdAt: DateTime(2026),
      categoryId: 'jidlo',
    );
    expect(p.toJson()['category'], 'jidlo');
    expect(Puzzle.fromJson(p.toJson()).categoryId, 'jidlo');

    final other = Puzzle.fromJson({...p.toJson()}..remove('category'));
    expect(other.categoryId, PuzzleCategory.otherId);
    expect(other.toJson().containsKey('category'), isFalse);
  });
}
