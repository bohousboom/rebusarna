import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/puzzle_search.dart';
import '../shared/puzzle_card.dart';

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
                itemBuilder: (context, i) => _Thumb(
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.puzzle, required this.solved});

  final Puzzle puzzle;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/puzzle/${puzzle.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: solved ? Colors.green : Colors.black12,
            width: solved ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PuzzleImage(puzzle.image, fit: BoxFit.cover, cacheWidth: 360),
            if (solved)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  color: Colors.green.shade700,
                  child: Text(
                    puzzle.solution,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
