/// Neprůhledný token pro sdílený odkaz: z id rébusu (např. "seed-myslenka") nejde
/// na první pohled poznat řešení. Není to šifra, jen aby odkaz nic neprozradil.
String shareToken(String puzzleId) {
  // Dvě 32bitové FNV-1a s různým základem (bezpečné i v JS číslech na webu).
  var a = 0x811c9dc5;
  var b = 0x01000193 ^ 0x5bd1e995;
  for (final c in puzzleId.codeUnits) {
    a = ((a ^ c) * 0x01000193) & 0xffffffff;
    b = ((b ^ c) * 0x85ebca6b) & 0xffffffff;
  }
  return 'k${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}';
}
