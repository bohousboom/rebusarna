import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/puzzle.dart';
import '../domain/models/word_type.dart';
import 'puzzle_repository.dart';

const _kBucket = 'puzzle-images';
const _kMaxUploadBytes = 1024 * 1024; // shodně s limitem bucketu

/// Vestavěné rébusy ze seedu + sdílené rébusy ze Supabase.
class SupabasePuzzleRepository implements PuzzleRepository {
  SupabasePuzzleRepository(this._client, {required this.loadSeed});

  final SupabaseClient _client;
  final Future<String> Function() loadSeed;

  @override
  Future<List<Puzzle>> getAll() async {
    final seed = [
      for (final p in jsonDecode(await loadSeed()) as List)
        Puzzle.fromJson(p as Map<String, dynamic>),
    ];
    try {
      final rows = await _client
          .from('puzzles')
          .select()
          .order('created_at', ascending: false);
      return [...seed, for (final r in rows) _fromRow(r)];
    } catch (_) {
      return seed; // offline: aspoň vestavěné rébusy
    }
  }

  @override
  Future<Puzzle> create(Puzzle puzzle, {UploadImage? upload}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Pro nahrávání se musíš přihlásit.');
    if (upload == null) throw ArgumentError('Chybí obrázek.');
    if (upload.bytes.length > _kMaxUploadBytes) {
      throw StateError('Obrázek je větší než 1 MB. Vyber menší.');
    }

    final ext = upload.extension.toLowerCase();
    final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _client.storage.from(_kBucket).uploadBinary(
          path,
          upload.bytes,
          fileOptions: FileOptions(contentType: _mime(ext)),
        );

    try {
      final row = await _client
          .from('puzzles')
          .insert({
            'image_path': path,
            'solution': puzzle.solution,
            'meaning': puzzle.meaning,
            'explanation': puzzle.explanation,
            'word_type': puzzle.wordType.name,
            'difficulty': puzzle.difficulty,
            'author_name': puzzle.authorName,
          })
          .select()
          .single();
      return _fromRow(row);
    } catch (_) {
      // nevznikne osiřelý soubor
      await _client.storage.from(_kBucket).remove([path]);
      rethrow;
    }
  }

  String _mime(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  Puzzle _fromRow(Map<String, dynamic> r) => Puzzle(
        id: r['id'] as String,
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
