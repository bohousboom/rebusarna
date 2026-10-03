import 'dart:typed_data';

import '../domain/models/puzzle.dart';

/// Obrázek k nahrání při vytvoření nebo úpravě rébusu.
class UploadImage {
  const UploadImage({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// Přípona bez tečky (jpg, png, webp).
  final String extension;
}

/// Výsledek importu vestavěných rébusů do účtu.
class ImportResult {
  const ImportResult({required this.imported, required this.failed, this.firstError});

  final int imported;
  final int failed;

  /// Text první chyby (pro diagnostiku).
  final String? firstError;
}

/// Zdroj rébusů. UI zná jen toto rozhraní, takže implementaci jde vyměnit
/// (lokální úložiště / Supabase).
abstract class PuzzleRepository {
  /// Všechny rébusy (vestavěné i uživatelské).
  Future<List<Puzzle>> getAll();

  /// Uloží nový rébus a vrátí ho (se skutečným id a adresou obrázku).
  Future<Puzzle> create(Puzzle puzzle, {UploadImage? upload});

  /// Upraví vlastní rébus; [upload] nahradí obrázek.
  Future<Puzzle> update(Puzzle puzzle, {UploadImage? upload});

  /// Smaže vlastní rébus (i s obrázkem).
  Future<void> delete(Puzzle puzzle);

  /// Nahraje vestavěné rébusy (assets) do účtu přihlášeného uživatele,
  /// aby je mohl upravovat. Už nahrané přeskočí.
  Future<ImportResult> importBuiltIn({void Function(int done, int total)? onProgress});
}
