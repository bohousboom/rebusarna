import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/difficulty.dart';

void main() {
  group('resultScore', () {
    test('bez chyb', () => expect(resultScore(wrong: 0, hints: 0, revealed: false), 0));
    test('špatné tipy se počítají nejvýše 5',
        () => expect(resultScore(wrong: 40, hints: 0, revealed: false), 5));
    test('nápovědy a odhalení',
        () => expect(resultScore(wrong: 1, hints: 2, revealed: true), 1 + 4 + 6));
  });

  group('computeDifficulty', () {
    test('bez hráčů platí obtížnost autora', () {
      for (final d in [1, 2, 3]) {
        expect(computeDifficulty(authorDifficulty: d, n: 0, avgScore: 0), d);
      }
    });
    test('několik hráčů autora ještě nepřebije', () {
      expect(computeDifficulty(authorDifficulty: 1, n: 1, avgScore: 8), 1);
    });
    test('hodně hráčů s velkým skóre zvedne obtížnost', () {
      expect(computeDifficulty(authorDifficulty: 1, n: 40, avgScore: 7), 3);
      expect(computeDifficulty(authorDifficulty: 1, n: 40, avgScore: 3), 2);
    });
    test('hodně hráčů bez chyb obtížnost sníží', () {
      expect(computeDifficulty(authorDifficulty: 3, n: 60, avgScore: 0.2), 1);
    });
    test('neznámá obtížnost se bere jako střední', () {
      expect(computeDifficulty(authorDifficulty: 9, n: 0, avgScore: 0), 2);
    });
  });
}
