import 'models/puzzle.dart';

/// Rébusy vytvořené uživateli za posledních [days] dní, nejnovější první.
/// Vestavěné (a do databáze naimportované) rébusy se nepočítají; [excludeOwnerId]
/// vynechá správcovy vlastní.
List<Puzzle> recentUserPuzzles(
  Iterable<Puzzle> all, {
  required DateTime now,
  int days = 7,
  String? excludeOwnerId,
}) {
  final since = now.subtract(Duration(days: days));
  return [
    for (final p in all)
      if (p.ownerId != null &&
          !p.id.startsWith('seed-') &&
          p.ownerId != excludeOwnerId &&
          p.createdAt.isAfter(since))
        p,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
