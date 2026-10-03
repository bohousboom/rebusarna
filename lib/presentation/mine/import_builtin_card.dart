import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/supabase_client.dart';

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

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final puzzles = ref.watch(puzzlesProvider).value;
    if (!isAdmin || puzzles == null) return const SizedBox.shrink();
    final pending =
        puzzles.where((p) => p.ownerId == null && p.id.startsWith('seed-')).length;
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
                Text('Nahrávám ${_done!} / $_total'),
              ] else
                FilledButton.tonal(
                  key: const Key('import-builtin-button'),
                  onPressed: _run,
                  child: const Text('Přidružit k mému účtu'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
