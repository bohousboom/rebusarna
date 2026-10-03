import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/puzzle.dart';
import 'puzzle_repository.dart';

const _kUserPuzzlesKey = 'user_puzzles';

/// Uloží rébusy do zařízení (JSON v shared_preferences); vestavěné se
/// načítají ze seed souboru.
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

  @override
  Future<List<Puzzle>> getAll() async {
    final seed = [
      for (final p in jsonDecode(await loadSeed()) as List)
        Puzzle.fromJson(p as Map<String, dynamic>),
    ];
    return [...seed, ..._readUser()];
  }

  @override
  Future<Puzzle> create(Puzzle puzzle) async {
    final all = [..._readUser(), puzzle];
    await _prefs.setString(
        _kUserPuzzlesKey, jsonEncode([for (final p in all) p.toJson()]));
    return puzzle;
  }
}
