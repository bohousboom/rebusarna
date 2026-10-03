import 'models/puzzle.dart';

/// Rébusy 18+ se zobrazí jen tehdy, když to uživatel výslovně zapnul.
List<Puzzle> visiblePuzzles(List<Puzzle> all, {required bool showAdult}) =>
    showAdult ? all : [for (final p in all) if (!p.adult) p];
