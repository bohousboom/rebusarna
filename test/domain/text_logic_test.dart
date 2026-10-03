import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/hints.dart';
import 'package:rebusarna/domain/text_logic.dart';

void main() {
  hintMaskTests();
  group('normalize', () {
    test('malá písmena a bez diakritiky', () {
      expect(normalize('Příliš žluťoučký kůň'), 'prilis zlutoucky kun');
    });
    test('ů, č, ř', () {
      expect(normalize('ů'), 'u');
      expect(normalize('Č'), 'c');
      expect(normalize('ŘEŘICHA'), 'rericha');
    });
    test('velká písmena', () => expect(normalize('PORANIT'), 'poranit'));
    test('mezery navíc', () {
      expect(normalize('  po   ranit  '), 'po ranit');
      expect(normalize('\tpo\nranit '), 'po ranit');
    });
    test('prázdný řetězec', () {
      expect(normalize(''), '');
      expect(normalize('   '), '');
    });
  });

  group('isCorrect', () {
    test('shoda bez ohledu na diakritiku a velikost', () {
      expect(isCorrect('Poranit', 'poranit'), isTrue);
      expect(isCorrect('ZRANIT', 'zranit'), isTrue);
      expect(isCorrect('kun', 'kůň'), isTrue);
      expect(isCorrect('KŮŇ', 'kun'), isTrue);
    });
    test('mezery navíc', () => expect(isCorrect('  poranit ', 'poranit'), isTrue));
    test('neshoda', () => expect(isCorrect('poranil', 'poranit'), isFalse));
    test('prázdný tip nikdy neplatí', () {
      expect(isCorrect('', ''), isFalse);
      expect(isCorrect('  ', 'poranit'), isFalse);
    });
    test('mezera uvnitř je významná',
        () => expect(isCorrect('po ranit', 'poranit'), isFalse));
  });

  group('hasNoAcute', () {
    test('bez čárky', () {
      expect(hasNoAcute('poranit'), isTrue);
      expect(hasNoAcute('kůň'), isTrue); // ů a ň nejsou čárka
      expect(hasNoAcute('čeřit'), isTrue); // háček není čárka
      expect(hasNoAcute('ŘEŽ'), isTrue);
    });
    test('s čárkou', () {
      for (final w in ['dům á', 'málo', 'kéž', 'síla', 'dóm', 'úl', 'rýže']) {
        expect(hasNoAcute(w), isFalse, reason: w);
      }
    });
    test('velká písmena s čárkou', () => expect(hasNoAcute('ÁNO'), isFalse));
    test('prázdné řešení', () => expect(hasNoAcute(''), isTrue));
  });

  group('hints', () {
    test('hintLetterCount', () {
      expect(hintLetterCount('poranit'), 7);
      expect(hintLetterCount('po ranit'), 7);
      expect(hintLetterCount(''), 0);
    });
    test('hintFirstLetter', () {
      expect(hintFirstLetter('Poranit'), 'p');
      expect(hintFirstLetter('  řeka'), 'ř');
      expect(hintFirstLetter(''), '');
    });
  });
}

void hintMaskTests() {
  group('hintMask', () {
    test('úroveň 0', () => expect(hintMask('poranit', 0), ''));
    test('úroveň 1', () => expect(hintMask('řeka', 1), '_ _ _ _'));
    test('úroveň 2', () => expect(hintMask('Řeka', 2), 'ř _ _ _'));
  });
}
