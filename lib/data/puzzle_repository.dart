import '../domain/models/puzzle.dart';

/// Zdroj rébusů. UI zná jen toto rozhraní, takže lokální implementaci
/// půjde později vyměnit (např. za SupabasePuzzleRepository).
abstract class PuzzleRepository {
  /// Všechny rébusy (vestavěné i uživatelské).
  Future<List<Puzzle>> getAll();

  /// Uloží nový rébus a vrátí ho.
  Future<Puzzle> create(Puzzle puzzle);
}
