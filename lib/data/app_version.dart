import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Adresa API s nejnovějším vydáním aplikace na GitHubu.
const String kLatestReleaseApi =
    'https://api.github.com/repos/bohousboom/rebusarna/releases/latest';

/// Nejnovější vydání z GitHubu.
class LatestRelease {
  const LatestRelease({required this.version, this.publishedAt});

  /// Číslo verze bez předpony „v“, např. `0.1.5`.
  final String version;
  final DateTime? publishedAt;
}

/// Z textu typu `v0.1.5` nebo `0.1.5+5` vytáhne [major, minor, patch].
/// Při nečitelném vstupu vrátí null.
List<int>? parseVersion(String raw) {
  final m = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(raw);
  if (m == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
}

/// True, když je [latest] vyšší než [installed]. Nečitelná verze = false.
bool isNewerVersion(String latest, String installed) {
  final a = parseVersion(latest);
  final b = parseVersion(installed);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// Z odpovědi GitHub API sestaví [LatestRelease]; při chybném tvaru vrátí null.
LatestRelease? parseLatestRelease(String body) {
  try {
    final json = jsonDecode(body);
    if (json is! Map) return null;
    final v = parseVersion('${json['tag_name']}');
    if (v == null) return null;
    return LatestRelease(
      version: v.join('.'),
      publishedAt: DateTime.tryParse('${json['published_at']}'),
    );
  } catch (_) {
    return null;
  }
}

/// Nejnovější vydání. Při jakékoli chybě (offline, limit API) vrátí null,
/// stránka pak verzi prostě nezobrazí.
final latestReleaseProvider = FutureProvider<LatestRelease?>((ref) async {
  try {
    final res = await http
        .get(
          Uri.parse(kLatestReleaseApi),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    return parseLatestRelease(utf8.decode(res.bodyBytes));
  } catch (_) {
    return null;
  }
});

/// Verze právě spuštěné aplikace (např. `0.1.5`), null když ji nejde zjistit.
final installedVersionProvider = FutureProvider<String?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return parseVersion(info.version)?.join('.');
  } catch (_) {
    return null;
  }
});
