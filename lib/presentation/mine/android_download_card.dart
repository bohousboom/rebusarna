import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';

/// Odkaz ke stažení Android aplikace (APK). Ukazuje se jen na webu.
class AndroidDownloadCard extends StatelessWidget {
  const AndroidDownloadCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return ListTile(
      key: const Key('android-download-tile'),
      dense: true,
      leading: const Icon(Icons.android),
      title: const Text('Stáhnout pro Android'),
      subtitle: const Text('Instalační soubor APK (povol instalaci z neznámých zdrojů)'),
      trailing: const Icon(Icons.download),
      onTap: () => launchUrl(Uri.parse(kAndroidApkUrl)),
    );
  }
}
