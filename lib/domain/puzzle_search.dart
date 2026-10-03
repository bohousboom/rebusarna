import 'models/puzzle.dart';
import 'text_logic.dart';

/// Filtr galerie podle řešení (bez diakritiky a velikosti písmen).
/// Přesná shoda a začátek slova jsou první.
List<Puzzle> searchPuzzles(List<Puzzle> all, String query) {
  final q = normalize(query);
  if (q.isEmpty) return all;
  final scored = <(int, int, Puzzle)>[];
  for (var i = 0; i < all.length; i++) {
    final n = normalize(all[i].solution);
    final int? s = n == q
        ? 0
        : n.startsWith(q)
            ? 1
            : n.contains(q)
                ? 2
                : null;
    if (s != null) scored.add((s, i, all[i]));
  }
  scored.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return c != 0 ? c : a.$2.compareTo(b.$2);
  });
  return [for (final s in scored) s.$3];
}
