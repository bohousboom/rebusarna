import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../create/puzzle_editor.dart';

/// Úprava vlastního rébusu (řešení, vysvětlení, obtížnost, obrázek).
class PuzzleEditScreen extends ConsumerWidget {
  const PuzzleEditScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzles = ref.watch(puzzlesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Upravit rébus')),
      body: SafeArea(
        child: puzzles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
            final p = all.where((x) => x.id == puzzleId).firstOrNull;
            if (p == null) return const Center(child: Text('Rébus nenalezen'));
            return PuzzleEditor(
              key: ValueKey(p.id),
              editing: p,
              onSaved: () => context.pop(),
            );
          },
        ),
      ),
    );
  }
}
