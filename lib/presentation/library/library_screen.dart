import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/puzzle_search.dart';
import '../shared/puzzle_thumb.dart';

/// Galerie všech rébusů s hledáním podle řešení (bez diakritiky).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final puzzles = ref.watch(puzzlesProvider);
    final solved = ref.watch(progressProvider.select((p) => p.solved));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Knihovna rébusů',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            key: const Key('library-search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Hledat podle řešení',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: puzzles.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Nepodařilo se načíst.\n$e')),
            data: (all) {
              final results = searchPuzzles(all, _query);
              if (results.isEmpty) {
                return const Center(child: Text('Nic nenalezeno'));
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  childAspectRatio: 2 / 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: results.length,
                itemBuilder: (context, i) => PuzzleThumb(
                  puzzle: results[i],
                  solved: solved.contains(results[i].id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
