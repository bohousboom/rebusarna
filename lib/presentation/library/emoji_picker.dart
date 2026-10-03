import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/emoji_library_loader.dart';
import '../../domain/emoji_search.dart';
import '../../domain/models/emoji_entry.dart';
import '../shared/token_glyph.dart';

/// Vyhledávací pole + mřížka emoji. Používá se v Knihovně i v editoru tvorby.
class EmojiPicker extends ConsumerStatefulWidget {
  const EmojiPicker({super.key, required this.onSelected});

  final void Function(EmojiEntry entry) onSelected;

  @override
  ConsumerState<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends ConsumerState<EmojiPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(emojiLibraryProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Hledat (např. pes, zub, pór)',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: library.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Knihovnu se nepodařilo načíst.\n$e')),
            data: (all) {
              final results = searchEmoji(all, _query);
              if (results.isEmpty) {
                return const Center(child: Text('Nic nenalezeno'));
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 110,
                  mainAxisExtent: 96,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: results.length,
                itemBuilder: (context, i) => _EmojiCell(
                  entry: results[i],
                  onTap: () => widget.onSelected(results[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmojiCell extends StatelessWidget {
  const _EmojiCell({required this.entry, required this.onTap});

  final EmojiEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: Center(child: TokenGlyph(entry.tokenValue)),
              ),
              const SizedBox(height: 4),
              Text(
                entry.cs,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
