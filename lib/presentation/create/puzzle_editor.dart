import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/puzzle_repository.dart' show UploadImage;
import '../../data/supabase_client.dart';
import '../../data/user_image_store.dart';
import '../../domain/languages.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/models/word_type.dart';
import '../../domain/puzzle_validation.dart';
import '../../domain/text_logic.dart';
import '../shared/create_help_sheet.dart';
import '../shared/puzzle_card.dart';
import '../shared/puzzle_thumb.dart';

/// Formulář rébusu: vytvoření nového ([editing] == null) nebo úprava vlastního.
const _helpHintSeenKey = 'create_help_hint_seen';

class PuzzleEditor extends ConsumerStatefulWidget {
  const PuzzleEditor({super.key, this.editing, required this.onSaved, this.title});

  final Puzzle? editing;
  final VoidCallback onSaved;
  final String? title;

  @override
  ConsumerState<PuzzleEditor> createState() => _PuzzleEditorState();
}

class _PuzzleEditorState extends ConsumerState<PuzzleEditor> {
  late final _solution = TextEditingController(text: widget.editing?.solution);
  late final _meaning = TextEditingController(text: widget.editing?.meaning);
  late final _explanation = TextEditingController(text: widget.editing?.explanation);
  late final _language = TextEditingController(text: widget.editing?.language);
  late final _author = TextEditingController(text: widget.editing?.authorName);
  PickedImage? _picked;
  late List<WordType> _wordTypes = [...(widget.editing?.wordTypes ?? const [WordType.noun])];
  late int _difficulty = widget.editing?.difficulty ?? 1;
  late bool _adult = widget.editing?.adult ?? false;
  late bool _plusMinus = widget.editing?.plusMinus ?? false;
  List<String> _errors = const [];
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHint());
  }

  /// Při prvním otevření jednou upozorní na nápovědu „?“.
  Future<void> _maybeShowHint() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!mounted || prefs.getBool(_helpHintSeenKey) == true) return;
    await prefs.setBool(_helpHintSeenKey, true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Nevíš, jak na to? Klepni na ?'),
      action: SnackBarAction(label: 'Ukázat', onPressed: () => showCreateHelp(context)),
    ));
  }

  /// Cesta k obrázku pro náhled: nově vybraný, nebo stávající.
  String? get _previewImage => _picked?.path ?? widget.editing?.image;

  @override
  void dispose() {
    _solution.dispose();
    _meaning.dispose();
    _explanation.dispose();
    _language.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ref.read(userImageStoreProvider).pick();
    if (picked != null) setState(() => _picked = picked);
  }

  Future<void> _save() async {
    final isForeign = _wordTypes.contains(WordType.foreign);
    final errors = [
      ...validateDraft(
      image: _previewImage,
      solution: _solution.text,
      explanation: _explanation.text,
      requireExplanation: !_isEdit,
    ),
      if (isForeign && _language.text.trim().isEmpty)
        'Doplň, z jakého jazyka se řešení hledá.',
    ];
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    final now = DateTime.now();
    final author = _author.text.trim();
    final meaning = _meaning.text.trim();
    final explanation = _explanation.text.trim();
    final fallbackAuthor =
        widget.editing?.authorName ?? displayNameOf(ref.read(currentUserProvider).value) ?? 'Anonym';
    final upload = _picked == null
        ? null
        : UploadImage(bytes: _picked!.bytes, extension: _picked!.extension);
    final repo = ref.read(puzzleRepositoryProvider);

    final puzzle = Puzzle(
      id: widget.editing?.id ?? 'user-${now.microsecondsSinceEpoch}',
      ownerId: widget.editing?.ownerId,
      image: _previewImage!,
      solution: _solution.text.trim(),
      meaning: meaning.isEmpty ? null : meaning,
      explanation: explanation.isEmpty ? null : explanation,
      language: isForeign ? _language.text.trim() : null,
      wordTypes: _wordTypes,
      difficulty: _difficulty,
      adult: _adult,
      plusMinus: _plusMinus,
      authorName: author.isEmpty ? fallbackAuthor : author,
      createdAt: widget.editing?.createdAt ?? now,
      ratingSum: widget.editing?.ratingSum ?? 0,
      ratingCount: widget.editing?.ratingCount ?? 0,
    );

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await repo.update(puzzle, upload: upload);
      } else {
        await repo.create(puzzle, upload: upload);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Uložení se nepovedlo: $e')));
      return;
    }
    ref.invalidate(puzzlesProvider);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!_isEdit) {
        _picked = null;
        _solution.clear();
        _meaning.clear();
        _explanation.clear();
        _language.clear();
        _wordTypes = [WordType.noun];
        _difficulty = 1;
        _adult = false;
        _plusMinus = false;
        _errors = const [];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Změny jsou uložené.' : 'Rébus je zveřejněný.')));
    widget.onSaved();
  }

  /// Moje dřívější rébusy se stejným řešením (jen vlastní; cizí autoři nevadí).
  List<Puzzle> _myDuplicates() {
    final userId = ref.watch(currentUserProvider).value?.id;
    final all = ref.watch(puzzlesProvider).value ?? const <Puzzle>[];
    final mine = all.where((p) =>
        p.id.startsWith('user-') || (userId != null && p.ownerId == userId));
    return ownDuplicates(mine.toList(), _solution.text, exceptId: widget.editing?.id);
  }

  @override
  Widget build(BuildContext context) {
    final duplicates = _myDuplicates();
    final cardHeight = (MediaQuery.sizeOf(context).height * 0.4).clamp(200.0, 440.0);
    final image = _previewImage;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.title != null) ...[
          Text(widget.title!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
        ],
        Center(
          child: SizedBox(
            height: cardHeight,
            width: cardHeight * 2 / 3 + 12,
            child: image == null
                ? _EmptyCard(onTap: _pickImage)
                : PuzzleCard(
                    image: image,
                    plusMinus: _plusMinus,
                    wordTypes: _wordTypes,
                    difficulty: _difficulty,
                    adult: _adult,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('pick-image-button'),
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(image == null ? 'Vybrat obrázek' : 'Změnit obrázek'),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('solution-field'),
          controller: _solution,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Řešení *',
            suffixIcon: HelpIconButton(sectionPrefix: formHelpSection),
          ),
        ),
        if (duplicates.isNotEmpty)
          Container(
            key: const Key('duplicate-warning'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade700),
            ),
            child: Row(
              children: [
                for (final d in duplicates.take(3))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 56,
                      height: 84,
                      child: PuzzleThumb(puzzle: d, solved: false),
                    ),
                  ),
                const Expanded(
                  child: Text('Rébus s tímto řešením už jsi vytvářel.'),
                ),
              ],
            ),
          ),
        SwitchListTile(
          key: const Key('plusminus-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Row(children: [
            Flexible(child: Text('Štítek ±')),
            HelpIconButton(sectionPrefix: formHelpSection),
          ]),
          subtitle: const Text('Zapni, když se řešení píše jinak, než se vyslovuje.'),
          value: _plusMinus,
          onChanged: (v) => setState(() => _plusMinus = v),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Flexible(
            child: Text('Druh slova (můžeš vybrat i více)',
                style: Theme.of(context).textTheme.labelLarge),
          ),
          const HelpIconButton(sectionPrefix: formHelpSection),
        ]),
        Wrap(
          spacing: 8,
          children: [
            for (final t in WordType.values)
              ChoiceChip(
                label: Text(t.label),
                avatar: Icon(wordTypeIcon(t), size: 18),
                selected: _wordTypes.contains(t),
                onSelected: (on) => setState(() {
                  if (on) {
                    _wordTypes = [..._wordTypes, t];
                  } else if (_wordTypes.length > 1) {
                    _wordTypes = [..._wordTypes]..remove(t);
                  }
                }),
              ),
          ],
        ),
        if (_wordTypes.contains(WordType.foreign)) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (name, flag) in kLanguages)
                ChoiceChip(
                  label: Text('$flag $name'),
                  selected: _language.text.trim().toLowerCase() == name,
                  onSelected: (_) => setState(() => _language.text = name),
                ),
            ],
          ),
          TextField(
            key: const Key('language-field'),
            controller: _language,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Z jakého jazyka *',
              helperText: 'Vyber nahoře, nebo napiš jiný. Hráč to uvidí v nápovědě.',
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Text('Obtížnost', style: Theme.of(context).textTheme.labelLarge),
          const HelpIconButton(sectionPrefix: formHelpSection),
        ]),
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
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('adult-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Obsah pro dospělé (18+)'),
          subtitle: const Text('Ukáže se jen hráčům, kteří si zobrazení 18+ zapnou.'),
          value: _adult,
          onChanged: (v) => setState(() => _adult = v),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('explanation-field'),
          controller: _explanation,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: _isEdit ? 'Vysvětlení řešení' : 'Vysvětlení řešení *',
            helperText: 'Jak se od obrázku dospěje k řešení.',
          ),
        ),
        const SizedBox(height: 12),
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
          onPressed: _saving ? null : _save,
          child: Text(_saving
              ? 'Ukládám…'
              : _isEdit
                  ? 'Uložit změny'
                  : 'Zveřejnit'),
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
