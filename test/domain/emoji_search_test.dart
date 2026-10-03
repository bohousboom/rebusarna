import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/data/emoji_library_loader.dart';
import 'package:rebusarna/domain/emoji_search.dart';
import 'package:rebusarna/domain/models/emoji_entry.dart';

void main() {
  final library = parseEmojiLibrary(
      File('assets/emoji_library.json').readAsStringSync());

  group('emoji_library.json', () {
    test('má alespoň 200 pojmů', () => expect(library.length, greaterThanOrEqualTo(200)));
    test('každý záznam je vyplněný', () {
      for (final e in library) {
        expect(e.emoji.trim(), isNotEmpty);
        expect(e.cs.trim(), isNotEmpty, reason: e.emoji);
      }
    });
    test('hlavní jména se neopakují', () {
      final names = library.map((e) => e.cs).toList();
      expect(names.toSet().length, names.length);
    });
    test('obsahuje slova ze seed puzzle', () {
      for (final w in ['pór', 'nit', 'kost', 'ruka', 'kráva', 'klíč', 'zvon', 'nos', 'zub', 'vlak', 'pes', 'žába', 'růže', 'pila', 'oko']) {
        expect(searchEmoji(library, w), isNotEmpty, reason: w);
      }
    });
  });

  group('searchEmoji', () {
    const all = [
      EmojiEntry(emoji: 'A', cs: 'kočka', synonyms: ['kotě']),
      EmojiEntry(emoji: 'B', cs: 'pes', synonyms: ['pejsek']),
      EmojiEntry(emoji: 'C', cs: 'cibule', synonyms: ['pór']),
      EmojiEntry(emoji: 'D', cs: 'kůň', synonyms: []),
      EmojiEntry(emoji: 'E', cs: 'hrací kostka', synonyms: []),
    ];

    test('prázdný dotaz vrací vše', () => expect(searchEmoji(all, '  '), all));
    test('bez diakritiky', () {
      expect(searchEmoji(all, 'kun').map((e) => e.emoji), ['D']);
      expect(searchEmoji(all, 'kocka').map((e) => e.emoji), ['A']);
    });
    test('velká písmena', () => expect(searchEmoji(all, 'PES').first.emoji, 'B'));
    test('synonyma', () {
      expect(searchEmoji(all, 'por').map((e) => e.emoji), ['C']);
      expect(searchEmoji(all, 'kote').map((e) => e.emoji), ['A']);
    });
    test('přesná shoda před částečnou', () {
      // "kost" je celé slovo v "hrací kostka"? ne – začátek slova; přesně nic
      expect(searchEmoji(all, 'p').first.emoji, 'B');
    });
    test('začátek slova uvnitř víceslovného jména', () {
      expect(searchEmoji(all, 'kostk').map((e) => e.emoji), ['E']);
    });
    test('žádná shoda', () => expect(searchEmoji(all, 'xyz'), isEmpty));
  });
}
