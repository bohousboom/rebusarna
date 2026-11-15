import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/supabase_client.dart';
import '../../domain/models/puzzle_category.dart';

/// Správce: seznam sad rébusů, nová sada, přejmenování a příznak „jen na vyžádání“. Ostatní hráči sady jen vybírají.
class CategoriesCard extends ConsumerWidget {
  const CategoriesCard({super.key});

  /// Dialog s názvem a příznakem „jen na vyžádání“; null = zrušeno.
  Future<({String name, bool onDemand})?> _askCategory(BuildContext context,
      {PuzzleCategory? initial}) {
    final controller = TextEditingController(text: initial?.label);
    var onDemand = initial?.onDemand ?? false;
    return showDialog<({String name, bool onDemand})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(initial == null ? 'Nová sada' : 'Upravit sadu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('category-name-field'),
                controller: controller,
                autofocus: true,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Název sady'),
              ),
              SwitchListTile(
                key: const Key('category-on-demand-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Jen na vyžádání'),
                subtitle: const Text('Nemíchat do „Všechny sady“, hraje se po výběru sady.'),
                value: onDemand,
                onChanged: (v) => setState(() => onDemand = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, (name: controller.text, onDemand: onDemand)),
              child: Text(initial == null ? 'Přidat' : 'Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(categoriesProvider);
    } catch (e) {
      if (context.mounted) {
        final msg = e is StateError
            ? e.message
            : e is ArgumentError
                ? '${e.message}'
                : '$e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final cats = ref.watch(categoriesProvider).value;
    if (!isAdmin || cats == null) return const SizedBox.shrink();
    final repo = ref.read(categoryRepositoryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sady rébusů (${cats.length})',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in cats)
                    ActionChip(
                      key: Key('category-chip-${c.id}'),
                      avatar: Icon(c.icon, size: 18),
                      label: Text(c.onDemand ? '${c.label} · na vyžádání' : c.label),
                      tooltip: c.id == PuzzleCategory.otherId
                          ? 'Výchozí sadu nejde upravit'
                          : 'Upravit',
                      onPressed: c.id == PuzzleCategory.otherId
                          ? null
                          : () async {
                              final r = await _askCategory(context, initial: c);
                              if (r == null || !context.mounted) return;
                              await _run(context, ref,
                                  () => repo.update(c.id, r.name, onDemand: r.onDemand));
                            },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                key: const Key('add-category-button'),
                onPressed: () async {
                  final r = await _askCategory(context);
                  if (r == null || !context.mounted) return;
                  await _run(context, ref, () async {
                    await repo.add(r.name, onDemand: r.onDemand);
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Přidat sadu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
