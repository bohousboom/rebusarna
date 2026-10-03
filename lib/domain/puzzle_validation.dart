/// Validace rozpracovaného rébusu při tvorbě. Vrací chybové hlášky (prázdný seznam = OK).
List<String> validateDraft({
  required String? image,
  required String solution,
  required String explanation,
}) {
  final errors = <String>[];
  if (image == null || image.isEmpty) errors.add('Vyber obrázek rébusu.');
  if (solution.trim().isEmpty) errors.add('Zadej řešení.');
  if (explanation.trim().isEmpty) errors.add('Napiš vysvětlení, jak se k řešení dospěje.');
  return errors;
}
