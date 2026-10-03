import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/user_image_store.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/models/word_type.dart';
import '../../domain/puzzle_validation.dart';
import '../shared/puzzle_card.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _solution = TextEditingController();
  final _meaning = TextEditingController();
  final _author = TextEditingController(text: 'Já');
  String? _image;
  WordType _wordType = WordType.noun;
  int _difficulty = 1;
  List<String> _errors = const [];

  @override
  void dispose() {
    _solution.dispose();
    _meaning.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await ref.read(userImageStoreProvider).pickAndStore();
    if (path != null) setState(() => _image = path);
  }

  Future<void> _publish() async {
    final errors = validateDraft(image: _image, solution: _solution.text);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    final now = DateTime.now();
    final author = _author.text.trim();
    final meaning = _meaning.text.trim();
    await ref.read(puzzleRepositoryProvider).create(Puzzle(
          id: 'user-${now.microsecondsSinceEpoch}',
          image: _image!,
          solution: _solution.text.trim(),
          meaning: meaning.isEmpty ? null : meaning,
          wordType: _wordType,
          difficulty: _difficulty,
          authorName: author.isEmpty ? 'Já' : author,
          createdAt: now,
        ));
    ref.invalidate(puzzlesProvider);
    if (!mounted) return;
    setState(() {
      _image = null;
      _solution.clear();
      _meaning.clear();
      _wordType = WordType.noun;
      _difficulty = 1;
      _errors = const [];
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Rébus je zveřejněný.')));
    context.go('/mine');
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = (MediaQuery.sizeOf(context).height * 0.4).clamp(200.0, 440.0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Vytvoř rébus', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            height: cardHeight,
            width: cardHeight * 2 / 3 + 12,
            child: _image == null
                ? _EmptyCard(onTap: _pickImage)
                : PuzzleCard(
                    image: _image!,
                    solution: _solution.text,
                    wordType: _wordType,
                    difficulty: _difficulty,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('pick-image-button'),
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(_image == null ? 'Vybrat obrázek' : 'Změnit obrázek'),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('solution-field'),
          controller: _solution,
          decoration: const InputDecoration(
            labelText: 'Řešení *',
            helperText: 'Štítek ± se doplní sám (řešení bez čárek).',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text('Druh slova', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final t in WordType.values)
              ChoiceChip(
                label: Text(t.label),
                avatar: Icon(wordTypeIcon(t), size: 18),
                selected: _wordType == t,
                onSelected: (_) => setState(() => _wordType = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Obtížnost', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 1, label: Text('Lehká')),
            ButtonSegment(value: 2, label: Text('Střední')),
            ButtonSegment(value: 3, label: Text('Těžká')),
          ],
          selected: {_difficulty},
          onSelectionChanged: (s) => setState(() => _difficulty = s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _meaning,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Význam (volitelně)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _author,
          decoration: const InputDecoration(labelText: 'Tvoje jméno'),
        ),
        if (_errors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _errors.join('\n'),
              key: const Key('create-errors'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('publish-button'),
          onPressed: _publish,
          child: const Text('Zveřejnit'),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outline),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 48, color: scheme.outline),
              const SizedBox(height: 8),
              const Text('Klepni a vyber obrázek'),
            ],
          ),
        ),
      ),
    );
  }
}
