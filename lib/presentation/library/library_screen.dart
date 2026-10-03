import 'package:flutter/material.dart';

import '../../domain/models/emoji_entry.dart';
import '../shared/token_glyph.dart';
import 'emoji_picker.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Knihovna obrázků',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: EmojiPicker(onSelected: (e) => _showDetail(context, e)),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, EmojiEntry e) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TokenGlyph(e.tokenValue, size: 80),
            const SizedBox(height: 8),
            Text(e.cs, style: Theme.of(context).textTheme.headlineSmall),
            if (e.synonyms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Také: ${e.synonyms.join(', ')}',
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
