import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/supabase_client.dart';
import '../../domain/models/puzzle.dart';

/// Nabídne správci (autorovi vestavěných obrázků) nahrát vestavěné rébusy do jeho účtu,
/// aby je mohl upravovat. Zmizí, když už jsou všechny nahrané.
class ImportBuiltInCard extends ConsumerStatefulWidget {
  const ImportBuiltInCard({super.key});

  @override
  ConsumerState<ImportBuiltInCard> createState() => _ImportBuiltInCardState();
}

class _ImportBuiltInCardState extends ConsumerState<ImportBuiltInCard> {
  int? _done;
  int _total = 0;

  bool get _running => _done != null;

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Přidružit vestavěné rébusy k účtu?'),
        content: const Text(
          'Obrázky se nahrají do tvého účtu v cloudu a staneš se jejich autorem, '
          'takže je budeš moct upravovat a mazat. Postup hráčů zůstane zachován. '
          'Udělej to jen, pokud jsou to tvoje obrázky.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Zrušit')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Nahrát')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _done = 0;
      _total = 0;
    });
    try {
      final result = await ref.read(puzzleRepositoryProvider).importBuiltIn(
            onProgress: (done, total) {
              if (mounted) {
                setState(() {
                  _done = done;
                  _total = total;
                });
              }
            },
          );
      ref.invalidate(puzzlesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.failed == 0
            ? 'Nahráno ${result.imported} rébusů.'
            : 'Nahráno ${result.imported}, selhalo ${result.failed}.\n${result.firstError ?? ''}'),
        duration: const Duration(seconds: 15),
        showCloseIcon: true,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import se nepovedl: $e')));
    } finally {
      if (mounted) setState(() => _done = null);
    }
  }

  /// Trvale smaže všechny dosud nepřidružené vestavěné rébusy (po potvrzení se seznamem).
  Future<void> _deletePending(List<Puzzle> pending) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Smazat natrvalo (${pending.length})?'),
        content: SingleChildScrollView(
          child: Text(
            'Tyto rébusy se trvale odstraní a nebudou se už nabízet:\n\n'
            '${pending.map((p) => p.solution).join(', ')}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Zrušit')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Smazat')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _done = 0;
      _total = pending.length;
    });
    final repo = ref.read(puzzleRepositoryProvider);
    var failed = 0;
    String? firstError;
    for (var i = 0; i < pending.length; i++) {
      try {
        await repo.delete(pending[i]);
      } catch (e) {
        failed++;
        firstError ??= '${pending[i].id}: $e';
      }
      if (mounted) setState(() => _done = i + 1);
    }
    ref.invalidate(puzzlesProvider);
    if (!mounted) return;
    setState(() => _done = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failed == 0
          ? 'Smazáno ${pending.length} rébusů.'
          : 'Smazáno ${pending.length - failed}, selhalo $failed.\n${firstError ?? ''}'),
      duration: const Duration(seconds: 15),
      showCloseIcon: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final puzzles = ref.watch(puzzlesProvider).value;
    if (!isAdmin || puzzles == null) return const SizedBox.shrink();
    final pendingList =
        puzzles.where((p) => p.ownerId == null && p.id.startsWith('seed-')).toList();
    final pending = pendingList.length;
    if (pending == 0 && !_running) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vestavěné rébusy ($pending) zatím nemají autora.'),
              const SizedBox(height: 8),
              if (_running) ...[
                LinearProgressIndicator(value: _total == 0 ? null : _done! / _total),
                const SizedBox(height: 4),
                Text('Pracuji ${_done!} / $_total'),
              ] else ...[
                FilledButton.tonal(
                  key: const Key('import-builtin-button'),
                  onPressed: _run,
                  child: const Text('Přidružit k mému účtu'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: const Key('delete-pending-button'),
                  onPressed: () => _deletePending(pendingList),
                  child: Text('Smazat tyto natrvalo ($pending)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
