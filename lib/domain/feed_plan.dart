import 'dart:math';

import 'models/puzzle.dart';

/// Jak se hráči řadí rébusy podle obtížnosti.
enum DifficultyMode {
  /// Nový hráč začíná lehkými, s přibývajícími vyřešenými se přidávají těžší.
  gradual('Postupně'),
  easy('Jen lehké'),
  medium('Jen střední'),
  hard('Jen těžké'),

  /// Vlastní poměr, např. 5 lehkých, 3 střední, 1 těžká dokola.
  custom('Vlastní mix'),

  /// Všechno náhodně.
  all('Vše náhodně');

  const DifficultyMode(this.label);
  final String label;
}

/// Kolik karet z každé obtížnosti v jednom kole (lehké, střední, těžké).
class DifficultyMix {
  const DifficultyMix(this.easy, this.medium, this.hard);

  final int easy;
  final int medium;
  final int hard;

  static const defaultCustom = DifficultyMix(5, 3, 1);

  List<int> get counts => [easy, medium, hard];

  bool get isEmpty => easy + medium + hard == 0;
}

/// Nastavení obtížnosti uložené v zařízení.
class DifficultySetting {
  const DifficultySetting({
    this.mode = DifficultyMode.gradual,
    this.custom = DifficultyMix.defaultCustom,
  });

  final DifficultyMode mode;
  final DifficultyMix custom;

  DifficultySetting copyWith({DifficultyMode? mode, DifficultyMix? custom}) =>
      DifficultySetting(mode: mode ?? this.mode, custom: custom ?? this.custom);

  /// Poměr pro právě vyřešený počet karet; null = bez omezení (vše náhodně).
  DifficultyMix? mixFor({required int solvedCount}) => switch (mode) {
        DifficultyMode.easy => const DifficultyMix(1, 0, 0),
        DifficultyMode.medium => const DifficultyMix(0, 1, 0),
        DifficultyMode.hard => const DifficultyMix(0, 0, 1),
        DifficultyMode.custom => custom.isEmpty ? null : custom,
        DifficultyMode.all => null,
        DifficultyMode.gradual => solvedCount < 10
            ? const DifficultyMix(3, 1, 0)
            : solvedCount < 30
                ? const DifficultyMix(5, 3, 1)
                : null,
      };
}

/// Pořadí feedu: nevyřešené (podle [mix]) první, potom vyřešené.
///
/// Obtížnost s nulovým počtem v [mix] se nezobrazí vůbec. Když v kole dojdou
/// karty dané obtížnosti, vezme se nejbližší povolená; když dojdou všechny
/// povolené, nevyřešená část končí.
List<Puzzle> orderFeed({
  required List<Puzzle> all,
  required Set<String> solved,
  required int Function(Puzzle) levelOf,
  required DifficultyMix? mix,
  Random? random,
}) {
  final rnd = random ?? Random();
  bool allowed(Puzzle p) => mix == null || mix.counts[levelOf(p).clamp(1, 3) - 1] > 0;

  final pool = all.where(allowed).toList();
  final todo = pool.where((p) => !solved.contains(p.id)).toList()..shuffle(rnd);
  final done = pool.where((p) => solved.contains(p.id)).toList()..shuffle(rnd);
  if (mix == null) return [...todo, ...done];

  final byLevel = <int, List<Puzzle>>{1: [], 2: [], 3: []};
  for (final p in todo) {
    byLevel[levelOf(p).clamp(1, 3)]!.add(p);
  }
  final cycle = <int>[
    for (var l = 1; l <= 3; l++) ...List.filled(mix.counts[l - 1], l),
  ];

  final ordered = <Puzzle>[];
  var i = 0;
  while (ordered.length < todo.length) {
    final want = cycle[i++ % cycle.length];
    final level = _nearestWithCards(byLevel, want);
    ordered.add(byLevel[level]!.removeLast());
  }
  return [...ordered, ...done];
}

int _nearestWithCards(Map<int, List<Puzzle>> byLevel, int want) {
  for (final d in [0, 1, -1, 2, -2]) {
    final l = want + d;
    if (byLevel[l]?.isNotEmpty ?? false) return l;
  }
  throw StateError('Žádná karta k výběru');
}
