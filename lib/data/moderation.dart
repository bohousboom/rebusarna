import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/report.dart';
import 'supabase_client.dart';

/// Nahlašování rébusů (hráč) a jejich vyřízení (správce).
class ModerationRepository {
  ModerationRepository(this._ref);

  final Ref _ref;

  /// Nahlásí rébus; jeden hráč smí nahlásit rébus jen jednou (opakování se ignoruje).
  Future<void> report(String puzzleId, ReportReason reason, {String? note}) async {
    final client = _ref.read(supabaseClientProvider);
    final user = _ref.read(currentUserProvider).value;
    if (client == null || user == null) {
      throw StateError('Pro nahlášení se musíš přihlásit.');
    }
    final trimmed = note?.trim();
    await client.from('puzzle_reports').upsert(
      {
        'puzzle_id': puzzleId,
        'reporter_id': user.id,
        'reason': reason.id,
        if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      },
      onConflict: 'puzzle_id,reporter_id',
      ignoreDuplicates: true,
    );
  }

  /// Zamítne (smaže) všechna nahlášení jednoho rébusu.
  Future<void> dismiss(String puzzleId) async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null) return;
    await client.from('puzzle_reports').delete().eq('puzzle_id', puzzleId);
    _ref.invalidate(reportsProvider);
  }
}

final moderationProvider = Provider<ModerationRepository>((ref) => ModerationRepository(ref));

/// Nahlášené rébusy pro správce (ostatním RLS nic nevrátí).
final reportsProvider = FutureProvider<List<ReportGroup>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final isAdmin = ref.watch(isAdminProvider).value ?? false;
  if (client == null || !isAdmin) return [];
  try {
    final rows = await client
        .from('puzzle_reports')
        .select('puzzle_id, reason, note, created_at');
    return groupReports([
      for (final r in rows)
        Report(
          puzzleId: r['puzzle_id'] as String,
          reason: ReportReason.fromId(r['reason'] as String?),
          note: r['note'] as String?,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
    ]);
  } catch (_) {
    return [];
  }
});
