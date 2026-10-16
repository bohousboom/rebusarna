import '../core/constants.dart';
import 'models/puzzle.dart';

const _diacritics = <String, String>{
  'á': 'a', 'ä': 'a', 'â': 'a', 'à': 'a',
  'č': 'c', 'ć': 'c',
  'ď': 'd',
  'é': 'e', 'ě': 'e', 'ë': 'e', 'è': 'e',
  'í': 'i', 'î': 'i',
  'ĺ': 'l', 'ľ': 'l', 'ł': 'l',
  'ň': 'n', 'ń': 'n',
  'ó': 'o', 'ö': 'o', 'ô': 'o', 'ò': 'o',
  'ř': 'r', 'ŕ': 'r',
  'š': 's', 'ś': 's',
  'ť': 't',
  'ú': 'u', 'ů': 'u', 'ü': 'u', 'û': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
};

/// Malá písmena, bez diakritiky, mezery na okrajích odstraněny a vnitřní sloučeny.
String normalize(String input) {
  final buf = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    buf.write(_diacritics[ch] ?? ch);
  }
  return buf.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool isCorrect(String tip, String solution) {
  final n = normalize(tip);
  return n.isNotEmpty && n == normalize(solution);
}

/// Pravda, když řešení neobsahuje žádný znak s čárkou (štítek ±).
bool hasNoAcute(String solution) {
  final lower = solution.toLowerCase();
  return !kAcuteChars.split('').any(lower.contains);
}

/// Rébusy, jejichž řešení obsahuje [query] (bez ohledu na velikost písmen a diakritiku).
List<Puzzle> searchBySolution(List<Puzzle> puzzles, String query) {
  final q = normalize(query);
  if (q.isEmpty) return puzzles;
  return puzzles.where((p) => normalize(p.solution).contains(q)).toList();
}

/// Vlastní rébusy ([mine]) se stejným řešením jako [solution]; [exceptId] se přeskočí (úprava).
List<Puzzle> ownDuplicates(List<Puzzle> mine, String solution, {String? exceptId}) {
  final n = normalize(solution);
  if (n.isEmpty) return const [];
  return mine.where((p) => p.id != exceptId && normalize(p.solution) == n).toList();
}
