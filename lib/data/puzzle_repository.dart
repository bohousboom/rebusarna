import 'dart:typed_data';

import '../domain/models/puzzle.dart';

/// Obrázek k nahrání při vytvoření rébusu.
class UploadImage {
  const UploadImage({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// Přípona bez tečky (jpg, png, webp).
  final String extension;
}

/// Zdroj rébusů. UI zná jen toto rozhraní, takže implementaci jde vyměnit
/// (lokální úložiště / Supabase).
abstract class PuzzleRepository {
  /// Všechny rébusy (vestavěné i uživatelské).
  Future<List<Puzzle>> getAll();

  /// Uloží nový rébus a vrátí ho (se skutečným id a adresou obrázku).
  Future<Puzzle> create(Puzzle puzzle, {UploadImage? upload});
}
