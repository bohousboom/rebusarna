/// Důvod nahlášení rébusu. [id] odpovídá hodnotě v databázi.
enum ReportReason {
  adult('adult', 'Měl by být označený 18+'),
  wrong('wrong', 'Chybné řešení nebo vysvětlení'),
  offensive('offensive', 'Nevhodný obsah'),
  other('other', 'Jiný důvod');

  const ReportReason(this.id, this.label);

  final String id;
  final String label;

  static ReportReason fromId(String? id) =>
      ReportReason.values.firstWhere((r) => r.id == id, orElse: () => ReportReason.other);
}

class Report {
  const Report({
    required this.puzzleId,
    required this.reason,
    required this.createdAt,
    this.note,
  });

  final String puzzleId;
  final ReportReason reason;
  final String? note;
  final DateTime createdAt;
}

/// Všechna nahlášení jednoho rébusu.
class ReportGroup {
  const ReportGroup({
    required this.puzzleId,
    required this.counts,
    required this.notes,
    required this.latest,
  });

  final String puzzleId;
  final Map<ReportReason, int> counts;
  final List<String> notes;
  final DateTime latest;

  int get total => counts.values.fold(0, (a, b) => a + b);
}

/// Seskupí nahlášení podle rébusu; nejvíce nahlášené (a nejnovější) jsou první.
List<ReportGroup> groupReports(Iterable<Report> reports) {
  final byPuzzle = <String, List<Report>>{};
  for (final r in reports) {
    byPuzzle.putIfAbsent(r.puzzleId, () => []).add(r);
  }
  final groups = [
    for (final e in byPuzzle.entries)
      ReportGroup(
        puzzleId: e.key,
        counts: {
          for (final reason in ReportReason.values)
            if (e.value.any((r) => r.reason == reason))
              reason: e.value.where((r) => r.reason == reason).length,
        },
        notes: [
          for (final r in e.value)
            if (r.note != null && r.note!.trim().isNotEmpty) r.note!.trim(),
        ],
        latest: e.value.map((r) => r.createdAt).reduce((a, b) => a.isAfter(b) ? a : b),
      ),
  ];
  groups.sort((a, b) {
    final c = b.total.compareTo(a.total);
    return c != 0 ? c : b.latest.compareTo(a.latest);
  });
  return groups;
}
