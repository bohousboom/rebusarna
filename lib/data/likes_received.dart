import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_client.dart';

/// Jeden hlas "líbí se mi" pro rébus přihlášeného autora.
class ReceivedLike {
  const ReceivedLike({required this.puzzleId, required this.name, required this.at});

  final String puzzleId;
  final String name;
  final DateTime at;
}

/// Kdo olajkoval moje rébusy (nejnovější první); jen pro přihlášeného autora.
final receivedLikesProvider = FutureProvider<List<ReceivedLike>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider).value;
  if (client == null || user == null) return const [];
  final rows = await client.rpc('my_puzzle_likes') as List;
  return [
    for (final r in rows)
      ReceivedLike(
        puzzleId: r['puzzle_id'] as String,
        name: r['liker_name'] as String? ?? 'Hráč',
        at: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      ),
  ];
});
