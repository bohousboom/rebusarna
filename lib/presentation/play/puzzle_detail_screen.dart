import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import 'play_screen.dart';
import 'puzzle_actions.dart';

/// Jeden rébus otevřený ze záložky Moje nebo z přehledu nahlášených.
/// Autor (a správce) ho může upravit nebo smazat, ostatní ho mohou nahlásit.
class PuzzleDetailScreen extends ConsumerWidget {
  const PuzzleDetailScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzles = ref.watch(puzzlesProvider);
    final puzzle = puzzles.value?.where((x) => x.id == puzzleId).firstOrNull;
    final perms = PuzzlePermissions.of(ref, puzzle);
    final canEdit = perms.canEdit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rébus'),
        actions: [
          if (perms.canReport)
            IconButton(
              key: const Key('report-button'),
              tooltip: 'Nahlásit',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => reportPuzzle(context, ref, puzzle!),
            ),
          if (canEdit)
            IconButton(
              key: const Key('edit-button'),
              tooltip: 'Upravit',
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/puzzle/${puzzle!.id}/edit'),
            ),
          if (perms.canDelete)
            IconButton(
              key: const Key('delete-button'),
              tooltip: 'Smazat',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirmDeletePuzzle(context, ref, puzzle!) && context.mounted) {
                  context.pop();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: puzzles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
            final p = all.where((x) => x.id == puzzleId).firstOrNull;
            if (p == null) return const Center(child: Text('Rébus nenalezen'));
            final showAdult = ref.watch(showAdultProvider);
            if (p.adult && !showAdult && !canEdit) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Tento rébus je označený 18+. Zobrazení zapneš v záložce Moje.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return PuzzlePage(
              key: ValueKey(p.id),
              puzzle: p,
              onNext: () => context.pop(),
              nextLabel: 'Zpět',
              showSkip: false,
            );
          },
        ),
      ),
    );
  }
}
