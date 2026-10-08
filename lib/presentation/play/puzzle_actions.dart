import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/moderation.dart';
import '../../data/providers.dart';
import '../../data/supabase_client.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/report.dart';

/// Co smí aktuální uživatel s jedním rébusem (nahlásit / upravit / smazat).
class PuzzlePermissions {
  const PuzzlePermissions({
    required this.canReport,
    required this.canEdit,
    required this.canDelete,
  });

  final bool canReport;
  final bool canEdit;
  final bool canDelete;

  bool get any => canReport || canEdit || canDelete;

  static PuzzlePermissions of(WidgetRef ref, Puzzle? puzzle) {
    final userId = ref.watch(currentUserProvider).value?.id;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final isOwner = userId != null && puzzle?.ownerId == userId;
    final inDatabase = puzzle != null && puzzle.ownerId != null;
    // Úpravy: autor, nebo správce u rébusu uloženého v databázi.
    final canEdit = isOwner || (isAdmin && inDatabase);
    // Správce smí trvale smazat i vestavěný rébus, který ještě není v jeho účtu.
    final isPendingBuiltIn =
        isAdmin && puzzle != null && puzzle.ownerId == null && puzzle.id.startsWith('seed-');
    // Nahlásit smí přihlášený cizí rébus.
    final canReport = userId != null && puzzle != null && !isOwner && !isAdmin;
    return PuzzlePermissions(
      canReport: canReport,
      canEdit: canEdit,
      canDelete: canEdit || isPendingBuiltIn,
    );
  }
}

/// Zeptá se na potvrzení a rébus smaže. Vrátí true, když se smazal.
Future<bool> confirmDeletePuzzle(BuildContext context, WidgetRef ref, Puzzle p) async {
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
  if (ok != true) return false;
  try {
    await ref.read(puzzleRepositoryProvider).delete(p);
    ref.invalidate(puzzlesProvider);
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Smazání se nepovedlo: $e')));
    }
    return false;
  }
}

/// Otevře dialog s důvodem a odešle nahlášení rébusu.
Future<void> reportPuzzle(BuildContext context, WidgetRef ref, Puzzle p) async {
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
