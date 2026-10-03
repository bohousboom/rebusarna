import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/supabase_client.dart';
import '../../domain/models/puzzle.dart';
import 'play_screen.dart';

/// Jeden rébus otevřený z Knihovny nebo ze záložky Moje.
/// Autor rébusu ho odsud může upravit nebo smazat.
class PuzzleDetailScreen extends ConsumerWidget {
  const PuzzleDetailScreen({super.key, required this.puzzleId});

  final String puzzleId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Puzzle p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat rébus?'),
        content: const Text('Rébus se trvale smaže i s obrázkem pro všechny uživatele.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Zrušit')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Smazat')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(puzzleRepositoryProvider).delete(p);
      ref.invalidate(puzzlesProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Smazání se nepovedlo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzles = ref.watch(puzzlesProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    final puzzle = puzzles.value?.where((x) => x.id == puzzleId).firstOrNull;
    final isOwner = userId != null && puzzle?.ownerId == userId;
    // Správce smí trvale smazat i vestavěný rébus, který ještě není v jeho účtu.
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final isPendingBuiltIn =
        isAdmin && puzzle != null && puzzle.ownerId == null && puzzle.id.startsWith('seed-');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rébus'),
        actions: [
          if (isOwner)
            IconButton(
              key: const Key('edit-button'),
              tooltip: 'Upravit',
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/puzzle/${puzzle!.id}/edit'),
            ),
          if (isOwner || isPendingBuiltIn)
            IconButton(
              key: const Key('delete-button'),
              tooltip: 'Smazat',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, puzzle!),
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
