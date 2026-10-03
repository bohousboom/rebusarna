/// Počet písmen řešení (mezery se nepočítají).
int hintLetterCount(String solution) =>
    solution.replaceAll(RegExp(r'\s'), '').length;

/// První písmeno řešení (malé, s původní diakritikou); prázdný řetězec pro prázdné řešení.
String hintFirstLetter(String solution) {
  final s = solution.trim();
  return s.isEmpty ? '' : s.substring(0, 1).toLowerCase();
}
