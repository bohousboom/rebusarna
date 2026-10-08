import 'models/puzzle.dart';

/// Rébusy 18+ se zobrazí jen tehdy, když to uživatel výslovně zapnul;
/// automaticky skryté (nahlášené) se nehrají nikdy.
List<Puzzle> visiblePuzzles(List<Puzzle> all, {required bool showAdult}) => [
      for (final p in all)
        if (!p.hidden && (showAdult || !p.adult)) p,
    ];
