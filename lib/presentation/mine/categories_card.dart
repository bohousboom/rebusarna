import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/supabase_client.dart';
import '../../domain/models/puzzle_category.dart';

/// Správce: seznam sad rébusů, nová sada a přejmenování. Ostatní hráči sady jen vybírají.
class CategoriesCard extends ConsumerWidget {
  const CategoriesCard({super.key});

  Future<String?> _askName(BuildContext context, {String? initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initial == null ? 'Nová sada' : 'Přejmenovat sadu'),
        content: TextField(
          key: const Key('category-name-field'),
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Název sady'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(initial == null ? 'Přidat' : 'Uložit'),
          ),
        ],
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
                      label: Text(c.label),
                      tooltip: c.id == PuzzleCategory.otherId
                          ? 'Výchozí sadu nejde přejmenovat'
                          : 'Přejmenovat',
                      onPressed: c.id == PuzzleCategory.otherId
                          ? null
                          : () async {
                              final name = await _askName(context, initial: c.label);
                              if (name == null || !context.mounted) return;
                              await _run(context, ref, () => repo.rename(c.id, name));
                            },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                key: const Key('add-category-button'),
                onPressed: () async {
                  final name = await _askName(context);
                  if (name == null || !context.mounted) return;
                  await _run(context, ref, () async {
                    await repo.add(name);
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
