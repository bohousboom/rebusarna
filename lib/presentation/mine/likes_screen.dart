import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/likes_received.dart';
import '../../data/providers.dart';
import '../shared/puzzle_card.dart';

/// Které moje rébusy někdo olajkoval a kdo to byl.
class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  String _date(DateTime t) => '${t.day}. ${t.month}. ${t.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(receivedLikesProvider);
    final puzzles = ref.watch(puzzlesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Líbilo se hráčům')),
      body: SafeArea(
        child: likes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Nepodařilo se načíst.\n$e', textAlign: TextAlign.center),
          )),
          data: (list) {
            if (list.isEmpty) {
              return const Center(child: Text('Zatím tvé rébusy nikdo neolajkoval.'));
            }
            final byPuzzle = <String, List<ReceivedLike>>{};
            for (final l in list) {
              byPuzzle.putIfAbsent(l.puzzleId, () => []).add(l);
            }
            // Nejvíc olajkované první.
            final ids = byPuzzle.keys.toList()
              ..sort((a, b) => byPuzzle[b]!.length.compareTo(byPuzzle[a]!.length));
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(receivedLikesProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: ids.length,
                itemBuilder: (context, i) {
                  final id = ids[i];
                  final given = byPuzzle[id]!;
                  final puzzle = puzzles
                      .where((p) => p.id == id)
                      .firstOrNull;
                  return Card(
                    child: ExpansionTile(
                      key: Key('likes-$id'),
                      leading: SizedBox(
                        width: 48,
                        height: 72,
                        child: puzzle == null
                            ? const Icon(Icons.help_outline)
                            : PuzzleImage(puzzle.image, fit: BoxFit.cover, cacheWidth: 200),
                      ),
                      title: Text(puzzle?.solution ?? '(rébus už neexistuje)'),
                      subtitle: Text('♥ ${given.length}'),
                      children: [
                        for (final l in given)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.favorite, color: Colors.red, size: 18),
                            title: Text(l.name),
                            trailing: Text(_date(l.at)),
                          ),
                        if (puzzle != null)
                          TextButton(
                            onPressed: () => context.push('/puzzle/${puzzle.id}'),
                            child: const Text('Otevřít rébus'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
