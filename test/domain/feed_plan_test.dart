import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rebusarna/domain/feed_plan.dart';
import 'package:rebusarna/domain/models/puzzle.dart';
import 'package:rebusarna/domain/models/word_type.dart';

Puzzle _p(String id, int difficulty) => Puzzle(
      id: id,
      image: 'x',
      solution: id,
      wordTypes: [WordType.verb],
      difficulty: difficulty,
      authorName: 't',
      createdAt: DateTime(2026),
    );

List<Puzzle> _deck({int easy = 0, int medium = 0, int hard = 0}) => [
      for (var i = 0; i < easy; i++) _p('e$i', 1),
      for (var i = 0; i < medium; i++) _p('m$i', 2),
      for (var i = 0; i < hard; i++) _p('h$i', 3),
    ];

List<Puzzle> _order(List<Puzzle> all, DifficultyMix? mix, {Set<String> solved = const {}}) =>
    orderFeed(
      all: all,
      solved: solved,
      levelOf: (p) => p.difficulty,
      mix: mix,
      random: Random(1),
    );

void main() {
  test('mix 5/3/1 dává dokola 5 lehkých, 3 střední, 1 těžkou', () {
    final feed = _order(_deck(easy: 10, medium: 6, hard: 2), const DifficultyMix(5, 3, 1));
    final levels = [for (final p in feed) p.difficulty];
    expect(levels.take(9), [1, 1, 1, 1, 1, 2, 2, 2, 3]);
    expect(levels.skip(9).take(9), [1, 1, 1, 1, 1, 2, 2, 2, 3]);
    expect(feed.length, 18);
  });

  test('jen lehké: těžké a střední se nezobrazí', () {
    final feed = _order(_deck(easy: 3, medium: 3, hard: 3), const DifficultyMix(1, 0, 0));
    expect(feed.map((p) => p.difficulty).toSet(), {1});
    expect(feed.length, 3);
  });

  test('když dojdou těžké, vezme se nejbližší povolená obtížnost', () {
    final feed = _order(_deck(easy: 4, medium: 4, hard: 1), const DifficultyMix(2, 1, 1));
    expect(feed.length, 9);
    expect(feed.map((p) => p.id).toSet().length, 9);
  });

  test('nevyřešené jdou před vyřešenými', () {
    final all = _deck(easy: 4);
    final feed = _order(all, const DifficultyMix(1, 1, 1), solved: {'e0', 'e1'});
    expect(feed.take(2).every((p) => !{'e0', 'e1'}.contains(p.id)), isTrue);
    expect(feed.skip(2).every((p) => {'e0', 'e1'}.contains(p.id)), isTrue);
  });

  test('bez mixu jsou všechny karty, nevyřešené první', () {
    final feed = _order(_deck(easy: 2, medium: 2, hard: 2), null, solved: {'h0'});
    expect(feed.length, 6);
    expect(feed.last.id, 'h0');
  });

  group('DifficultySetting.mixFor', () {
    test('postupně: nováček dostane hlavně lehké, zkušený vše', () {
      const s = DifficultySetting();
      expect(s.mixFor(solvedCount: 0)!.hard, 0);
      expect(s.mixFor(solvedCount: 0)!.easy, greaterThan(s.mixFor(solvedCount: 0)!.medium));
      expect(s.mixFor(solvedCount: 15)!.hard, 1);
      expect(s.mixFor(solvedCount: 50), isNull);
    });
    test('prázdný vlastní mix = vše náhodně', () {
      const s = DifficultySetting(mode: DifficultyMode.custom, custom: DifficultyMix(0, 0, 0));
      expect(s.mixFor(solvedCount: 0), isNull);
    });
  });
}
