import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/moderation.dart';
import '../../data/providers.dart';
import '../../data/supabase_client.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/report.dart';
import 'play_screen.dart';

/// Jeden rébus otevřený ze záložky Moje nebo z přehledu nahlášených.
/// Autor (a správce) ho může upravit nebo smazat, ostatní ho mohou nahlásit.
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

  Future<void> _report(BuildContext context, WidgetRef ref, Puzzle p) async {
    final result = await showDialog<(ReportReason, String)>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(moderationProvider).report(p.id, result.$1, note: result.$2);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Díky, rébus je nahlášený.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Nahlášení se nepovedlo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzles = ref.watch(puzzlesProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    final puzzle = puzzles.value?.where((x) => x.id == puzzleId).firstOrNull;
    final isOwner = userId != null && puzzle?.ownerId == userId;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final inDatabase = puzzle != null && puzzle.ownerId != null;
    // Úpravy: autor, nebo správce u rébusu uloženého v databázi.
    final canEdit = isOwner || (isAdmin && inDatabase);
    // Správce smí trvale smazat i vestavěný rébus, který ještě není v jeho účtu.
    final isPendingBuiltIn =
        isAdmin && puzzle != null && puzzle.ownerId == null && puzzle.id.startsWith('seed-');
    // Nahlásit smí přihlášený cizí rébus.
    final canReport = userId != null && puzzle != null && !isOwner && !isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rébus'),
        actions: [
          if (canReport)
            IconButton(
              key: const Key('report-button'),
              tooltip: 'Nahlásit',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _report(context, ref, puzzle),
            ),
          if (canEdit)
            IconButton(
              key: const Key('edit-button'),
              tooltip: 'Upravit',
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/puzzle/${puzzle!.id}/edit'),
            ),
          if (canEdit || isPendingBuiltIn)
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

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason _reason = ReportReason.adult;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nahlásit rébus'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v ?? _reason),
              child: Column(
                children: [
                  for (final r in ReportReason.values)
                    RadioListTile<ReportReason>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.label),
                      value: r,
                    ),
                ],
              ),
            ),
            TextField(
              key: const Key('report-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Poznámka (volitelně)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušit')),
        FilledButton(
          key: const Key('report-send'),
          onPressed: () => Navigator.pop(context, (_reason, _note.text)),
          child: const Text('Odeslat'),
        ),
      ],
    );
  }
}
