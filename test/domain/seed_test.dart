import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/models/puzzle.dart';

List<Puzzle> _seed() => [
      for (final p in jsonDecode(File('assets/seed_puzzles.json').readAsStringSync()) as List)
        Puzzle.fromJson(p as Map<String, dynamic>),
    ];

void main() {
  final seed = _seed();

  group('seed_puzzles.json', () {
    test('není prázdný a má unikátní id', () {
      expect(seed, isNotEmpty);
      expect(seed.map((p) => p.id).toSet().length, seed.length);
    });
    test('každý rébus má existující obrázek a řešení', () {
      for (final p in seed) {
        expect(p.solution.trim(), isNotEmpty, reason: p.id);
        expect(File(p.image).existsSync(), isTrue, reason: p.image);
        expect(p.difficulty, inInclusiveRange(1, 3), reason: p.id);
      }
    });
    test('JSON round-trip', () {
      final p = seed.first;
      expect(Puzzle.fromJson(p.toJson()).toJson(), p.toJson());
    });
  });
}
