/// Počet písmen řešení (mezery se nepočítají).
int hintLetterCount(String solution) =>
    solution.replaceAll(RegExp(r'\s'), '').length;

/// První písmeno řešení (malé, s původní diakritikou); prázdný řetězec pro prázdné řešení.
String hintFirstLetter(String solution) {
  final s = solution.trim();
  return s.isEmpty ? '' : s.substring(0, 1).toLowerCase();
}

/// Text nápovědy: úroveň 1 = jen počet písmen (_ _ _), úroveň 2 = navíc první písmeno.
String hintMask(String solution, int level) {
  if (level <= 0) return '';
  final chars = solution.trim().split('');
  final out = <String>[];
  for (var i = 0; i < chars.length; i++) {
    if (chars[i].trim().isEmpty) {
      out.add(' ');
    } else if (i == 0 && level >= 2) {
      out.add(chars[i].toLowerCase());
    } else {
      out.add('_');
    }
  }
  return out.join(' ');
}
