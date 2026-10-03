import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/puzzle.dart';
import '../domain/models/word_type.dart';
import 'puzzle_repository.dart';

const _kBucket = 'puzzle-images';
const _kMaxUploadBytes = 1024 * 1024; // shodně s limitem bucketu
const _kSeedPrefix = 'seed-';

/// Vestavěné rébusy ze seedu + sdílené rébusy ze Supabase.
/// Vestavěné rébusy importované do účtu mají v databázi `seed_key` = původní id
/// a vestavěná kopie se pak nezobrazuje dvakrát.
class SupabasePuzzleRepository implements PuzzleRepository {
  SupabasePuzzleRepository(this._client, {required this.loadSeed});

  final SupabaseClient _client;
  final Future<String> Function() loadSeed;

  Future<List<Puzzle>> _loadSeed() async => [
        for (final p in jsonDecode(await loadSeed()) as List)
          Puzzle.fromJson(p as Map<String, dynamic>),
      ];

  @override
  Future<List<Puzzle>> getAll() async {
    final seed = await _loadSeed();
    try {
      final rows = await _client
          .from('puzzles')
          .select()
          .order('created_at', ascending: false);
      final remote = [for (final r in rows) _fromRow(r)];
      final importedIds = {for (final p in remote) p.id};
      return [
        for (final p in seed)
          if (!importedIds.contains(p.id)) p,
        ...remote,
      ];
    } catch (_) {
      return seed; // offline: aspoň vestavěné rébusy
    }
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Pro tuto akci se musíš přihlásit.');
    return user;
  }

  /// Nahraje obrázek do složky uživatele a vrátí cestu v úložišti.
  Future<String> _upload(String uid, UploadImage upload, {String? name}) async {
    if (upload.bytes.length > _kMaxUploadBytes) {
      throw StateError('Obrázek je větší než 1 MB. Vyber menší.');
    }
    final ext = upload.extension.toLowerCase();
    final path = '$uid/${name ?? DateTime.now().microsecondsSinceEpoch}.$ext';
    await _client.storage.from(_kBucket).uploadBinary(
          path,
          upload.bytes,
          fileOptions: FileOptions(contentType: _mime(ext), upsert: name != null),
        );
    return path;
  }

  /// Řádek podle id: vestavěné (importované) se hledají přes seed_key.
  PostgrestFilterBuilder<T> _byId<T>(PostgrestFilterBuilder<T> q, String id) =>
      id.startsWith(_kSeedPrefix) ? q.eq('seed_key', id) : q.eq('id', id);

  @override
  Future<Puzzle> create(Puzzle puzzle, {UploadImage? upload}) async {
    final user = _requireUser();
    if (upload == null) throw ArgumentError('Chybí obrázek.');
    final path = await _upload(user.id, upload);
    try {
      final row = await _client
          .from('puzzles')
          .insert(_toRow(puzzle, path))
          .select()
          .single();
      return _fromRow(row);
    } catch (_) {
      await _client.storage.from(_kBucket).remove([path]); // žádný osiřelý soubor
      rethrow;
    }
  }

  @override
  Future<Puzzle> update(Puzzle puzzle, {UploadImage? upload}) async {
    final user = _requireUser();
    final values = <String, dynamic>{
      'solution': puzzle.solution,
      'meaning': puzzle.meaning,
      'explanation': puzzle.explanation,
      'word_type': puzzle.wordType.name,
      'difficulty': puzzle.difficulty,
      'author_name': puzzle.authorName,
    };

    String? oldPath;
    if (upload != null) {
      final old = await _byId(_client.from('puzzles').select('image_path'), puzzle.id)
          .maybeSingle();
      oldPath = old?['image_path'] as String?;
      values['image_path'] = await _upload(user.id, upload);
    }

    final row = await _byId(_client.from('puzzles').update(values), puzzle.id)
        .select()
        .single();
    if (oldPath != null) {
      try {
        await _client.storage.from(_kBucket).remove([oldPath]);
      } catch (_) {}
    }
    return _fromRow(row);
  }

  @override
  Future<void> delete(Puzzle puzzle) async {
    _requireUser();
    final row = await _byId(_client.from('puzzles').select('image_path'), puzzle.id)
        .maybeSingle();
    await _byId(_client.from('puzzles').delete(), puzzle.id);
    final path = row?['image_path'] as String?;
    if (path != null) {
      try {
        await _client.storage.from(_kBucket).remove([path]);
      } catch (_) {}
    }
  }

  @override
  Future<ImportResult> importBuiltIn({void Function(int done, int total)? onProgress}) async {
    final user = _requireUser();
    final seed = await _loadSeed();
    final existing = await _client.from('puzzles').select('seed_key').not('seed_key', 'is', null);
    final have = {for (final r in existing) r['seed_key'] as String};
    final todo = [for (final p in seed) if (!have.contains(p.id)) p];

    var imported = 0, failed = 0;
    for (var i = 0; i < todo.length; i++) {
      final p = todo[i];
      String? path;
      try {
        final data = await rootBundle.load(p.image);
        final ext = p.image.split('.').last;
        path = await _upload(
          user.id,
          UploadImage(bytes: data.buffer.asUint8List(), extension: ext),
          name: p.id,
        );
        await _client.from('puzzles').insert({
          ..._toRow(p, path),
          'seed_key': p.id,
        });
        imported++;
      } catch (_) {
        failed++;
        if (path != null) {
          try {
            await _client.storage.from(_kBucket).remove([path]);
          } catch (_) {}
        }
      }
      onProgress?.call(i + 1, todo.length);
    }
    return ImportResult(imported: imported, failed: failed);
  }

  Map<String, dynamic> _toRow(Puzzle p, String imagePath) => {
        'image_path': imagePath,
        'solution': p.solution,
        'meaning': p.meaning,
        'explanation': p.explanation,
        'word_type': p.wordType.name,
        'difficulty': p.difficulty,
        'author_name': p.authorName,
      };

  String _mime(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  Puzzle _fromRow(Map<String, dynamic> r) => Puzzle(
        id: (r['seed_key'] as String?) ?? r['id'] as String,
        ownerId: r['owner_id'] as String?,
        image: _client.storage.from(_kBucket).getPublicUrl(r['image_path'] as String),
        solution: r['solution'] as String,
        meaning: r['meaning'] as String?,
        explanation: r['explanation'] as String?,
        wordType: WordType.fromName(r['word_type'] as String?),
        difficulty: (r['difficulty'] as num?)?.toInt() ?? 1,
        authorName: r['author_name'] as String? ?? 'Anonym',
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        ratingSum: (r['rating_sum'] as num?)?.toInt() ?? 0,
        ratingCount: (r['rating_count'] as num?)?.toInt() ?? 0,
      );
}
