import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';

/// Samostatná stránka `/download`. Není nikde odkazovaná, dostaneš se na ni
/// jen zadáním adresy.
class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iosReady = kIosAppUrl.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Stáhnout aplikaci')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              FilledButton.icon(
                key: const Key('download-android'),
                onPressed: () => launchUrl(Uri.parse(kAndroidApkUrl)),
                icon: const Icon(Icons.android),
                label: const Text('Stáhnout pro Android'),
              ),
              const SizedBox(height: 6),
              Text(
                'Instalační soubor APK (povol instalaci z neznámých zdrojů)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              if (iosReady)
                FilledButton.icon(
                  key: const Key('download-ios'),
                  onPressed: () => launchUrl(Uri.parse(kIosAppUrl)),
                  icon: const Icon(Icons.apple),
                  label: const Text('Stáhnout pro iOS'),
                ),
              if (!iosReady)
                Card(
                  key: const Key('ios-guide'),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.apple),
                          const SizedBox(width: 8),
                          Text('Instalace na iPhone / iPad',
                              style: Theme.of(context).textTheme.titleMedium),
                        ]),
                        const SizedBox(height: 12),
                        const Text('1. Otevři tuto stránku v Safari (jiný prohlížeč to neumí).'),
                        const SizedBox(height: 6),
                        const Text('2. Klepni na tlačítko Sdílet (čtvereček se šipkou nahoru).'),
                        const SizedBox(height: 6),
                        const Text('3. Vyber „Přidat na plochu“ a potvrď „Přidat“.'),
                        const SizedBox(height: 6),
                        const Text('4. Rébusárnu pak spustíš ikonou na ploše, jako běžnou aplikaci.'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                key: const Key('download-back'),
                onPressed: () => context.go('/play'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Zpět do rébusárny'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
