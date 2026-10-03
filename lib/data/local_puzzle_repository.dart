import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/puzzle.dart';
import 'puzzle_repository.dart';

const _kUserPuzzlesKey = 'user_puzzles';

/// Uloží rébusy do zařízení (JSON v shared_preferences); vestavěné se
/// načítají ze seed souboru. Slouží bez Supabase (vývoj, testy).
class LocalPuzzleRepository implements PuzzleRepository {
  LocalPuzzleRepository(this._prefs, {required this.loadSeed});

  final SharedPreferences _prefs;
  final Future<String> Function() loadSeed;

  List<Puzzle> _readUser() {
    final raw = _prefs.getString(_kUserPuzzlesKey);
    if (raw == null) return [];
    return [
      for (final p in jsonDecode(raw) as List)
        Puzzle.fromJson(p as Map<String, dynamic>),
    ];
  }

  Future<void> _writeUser(List<Puzzle> all) => _prefs.setString(
      _kUserPuzzlesKey, jsonEncode([for (final p in all) p.toJson()]));

  @override
  Future<List<Puzzle>> getAll() async {
    final seed = [
      for (final p in jsonDecode(await loadSeed()) as List)
        Puzzle.fromJson(p as Map<String, dynamic>),
    ];
    return [...seed, ..._readUser()];
  }

  @override
  Future<Puzzle> create(Puzzle puzzle, {UploadImage? upload}) async {
    await _writeUser([..._readUser(), puzzle]);
    return puzzle;
  }

  @override
  Future<Puzzle> update(Puzzle puzzle, {UploadImage? upload}) async {
    await _writeUser([
      for (final p in _readUser()) p.id == puzzle.id ? puzzle : p,
    ]);
    return puzzle;
  }

  @override
  Future<void> delete(Puzzle puzzle) async {
    await _writeUser([for (final p in _readUser()) if (p.id != puzzle.id) p]);
  }

  @override
  Future<ImportResult> importBuiltIn({void Function(int done, int total)? onProgress}) {
    throw UnsupportedError('Import je k dispozici jen s přihlášením (Supabase).');
  }
}
