import 'models/emoji_entry.dart';
import 'text_logic.dart';

/// Vyhledá emoji podle českého jména nebo synonyma, bez ohledu na diakritiku
/// a velikost písmen. Nejlepší shody (přesná, začátek slova) jsou první.
List<EmojiEntry> searchEmoji(List<EmojiEntry> all, String query) {
  final q = normalize(query);
  if (q.isEmpty) return all;

  final scored = <(int, int, EmojiEntry)>[];
  for (var i = 0; i < all.length; i++) {
    final score = _score(all[i], q);
    if (score != null) scored.add((score, i, all[i]));
  }
  scored.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return c != 0 ? c : a.$2.compareTo(b.$2);
  });
  return [for (final s in scored) s.$3];
}

int? _score(EmojiEntry e, String q) {
  int? best;
  void consider(int s) {
    if (best == null || s < best!) best = s;
  }

  final names = [e.cs, ...e.synonyms];
  for (var i = 0; i < names.length; i++) {
    final n = normalize(names[i]);
    final offset = i == 0 ? 0 : 1; // hlavní jméno má přednost před synonymem
    if (n == q) {
      consider(0 + offset);
    } else if (n.startsWith(q)) {
      consider(2 + offset);
    } else if (n.contains(' $q')) {
      consider(4 + offset);
    } else if (n.contains(q)) {
      consider(6 + offset);
    }
  }
  return best;
}
