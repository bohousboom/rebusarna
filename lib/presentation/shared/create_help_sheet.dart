import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

const _helpAsset = 'assets/help/napoveda-tvorit.md';

/// Sekce nápovědy s polem formuláře (Řešení, Štítek ±, Druh slova, Obtížnost).
const formHelpSection = '8.';

/// Otevře nápovědu „Jak na to?“. Rozbalená je první sekce, nebo ta, jejíž
/// nadpis začíná na [sectionPrefix] (např. „8.“).
Future<void> showCreateHelp(BuildContext context, {String? sectionPrefix}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _HelpSheet(sectionPrefix: sectionPrefix),
    );

class HelpIconButton extends StatelessWidget {
  const HelpIconButton({super.key, this.sectionPrefix, this.size = 20});

  final String? sectionPrefix;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Jak na to?',
        visualDensity: VisualDensity.compact,
        iconSize: size,
        icon: const Icon(Icons.help_outline),
        onPressed: () => showCreateHelp(context, sectionPrefix: sectionPrefix),
      );
}

class _Section {
  const _Section(this.title, this.body);
  final String title;
  final String body;
}

/// Rozdělí markdown na sekce `## ...`; úvod před první sekcí se zahodí.
List<_Section> _parseSections(String md) {
  final sections = <_Section>[];
  String? title;
  final body = StringBuffer();
  var inCode = false;
  void flush() {
    if (title != null) sections.add(_Section(title!, body.toString().trim()));
    body.clear();
  }

  for (final line in md.split('\n')) {
    if (line.trimLeft().startsWith('```')) inCode = !inCode;
    if (!inCode && line.startsWith('## ')) {
      flush();
      title = line.substring(3).trim();
    } else if (title != null && (inCode || line.trim() != '---')) {
      body.writeln(line);
    }
  }
  flush();
  return sections;
}

/// Tělo sekce rozdělené na text (markdown) a bloky kódu (`true` = kód).
List<(bool, String)> _splitCode(String body) {
  final parts = <(bool, String)>[];
  final text = StringBuffer();
  final code = StringBuffer();
  var inCode = false;
  for (final line in body.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      if (inCode) {
        parts.add((true, code.toString().trim()));
        code.clear();
      } else if (text.toString().trim().isNotEmpty) {
        parts.add((false, text.toString().trim()));
        text.clear();
      }
      inCode = !inCode;
    } else {
      (inCode ? code : text).writeln(line);
    }
  }
  if (text.toString().trim().isNotEmpty) parts.add((false, text.toString().trim()));
  return parts;
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet({this.sectionPrefix});

  final String? sectionPrefix;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Jak na to?', style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'Zavřít',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: rootBundle.loadString(_helpAsset),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Nápovědu se nepodařilo načíst.'));
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final sections = _parseSections(snap.data!);
                final prefix = sectionPrefix;
                var open = prefix == null
                    ? 0
                    : sections.indexWhere((s) => s.title.startsWith(prefix));
                if (open < 0) open = 0;
                return ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  children: [
                    for (var i = 0; i < sections.length; i++)
                      ExpansionTile(
                        key: PageStorageKey('help-$i-$open'),
                        initiallyExpanded: i == open,
                        title: Text(sections[i].title,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (isCode, text) in _splitCode(sections[i].body))
                            isCode
                                ? _CodeBlock(code: text)
                                : MarkdownBody(
                                    data: text,
                                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                                  ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            widget.code,
            style: TextStyle(fontSize: 13, height: 1.35, color: scheme.onSurface),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.code));
                if (mounted) setState(() => _copied = true);
              },
              icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
              label: Text(_copied ? 'Zkopírováno' : 'Kopírovat'),
            ),
          ),
        ],
      ),
    );
  }
}
