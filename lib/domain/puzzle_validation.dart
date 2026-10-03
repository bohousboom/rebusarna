/// Validace rozpracovaného rébusu při tvorbě. Vrací chybové hlášky (prázdný seznam = OK).
List<String> validateDraft({required String? image, required String solution}) {
  final errors = <String>[];
  if (image == null || image.isEmpty) errors.add('Vyber obrázek rébusu.');
  if (solution.trim().isEmpty) errors.add('Zadej řešení.');
  return errors;
}
