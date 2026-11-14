import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/puzzle_category.dart';

/// Seznam sad rébusů. Čtou ho všichni, zakládat a přejmenovat smí jen správce
/// (hlídá to databáze). Bez serveru nebo při chybě se použije základní sada.
class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient? _client;

  Future<List<PuzzleCategory>> getAll() async {
    final c = _client;
    if (c == null) return PuzzleCategory.builtIn;
    try {
      final rows = await c.from('puzzle_categories').select().order('sort').order('label');
      final list = [
        for (final r in rows)
          PuzzleCategory(
            r['id'] as String,
            r['label'] as String,
            iconName: r['icon_name'] as String?,
          ),
      ];
      return list.isEmpty ? PuzzleCategory.builtIn : list;
    } catch (_) {
      return PuzzleCategory.builtIn;
    }
  }

  SupabaseClient get _db {
    final c = _client;
    if (c == null) throw StateError('Sady jde spravovat jen s připojením k serveru.');
    return c;
  }

  /// Založí novou sadu; vrací její id. Chyba, když název nejde použít nebo už existuje.
  Future<String> add(String label) async {
    final name = label.trim();
    final id = PuzzleCategory.idFromLabel(name);
    if (id.isEmpty) throw ArgumentError('Název sady musí obsahovat písmena nebo číslice.');
    try {
      await _db.from('puzzle_categories').insert({'id': id, 'label': name});
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw StateError('Sada s tímto názvem už existuje.');
      rethrow;
    }
    return id;
  }

  Future<void> rename(String id, String label) async {
    final name = label.trim();
    if (name.isEmpty) throw ArgumentError('Název sady nesmí být prázdný.');
    try {
      await _db.from('puzzle_categories').update({'label': name}).eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw StateError('Sada s tímto názvem už existuje.');
      rethrow;
    }
  }
}
