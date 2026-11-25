import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../data/app_version.dart';

/// Stránka `/download`: odkazy ke stažení a přehled verzí (nainstalovaná × nejnovější).
/// Není nikde odkazovaná, dostaneš se na ni jen zadáním adresy.
class DownloadScreen extends ConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iosReady = kIosAppUrl.isNotEmpty;
    final latest = ref.watch(latestReleaseProvider).value;
    // Nainstalovanou verzi má smysl porovnávat jen v aplikaci, ne na webu.
    final installed = kIsWeb ? null : ref.watch(installedVersionProvider).value;
    final outdated =
        latest != null &&
        installed != null &&
        isNewerVersion(latest.version, installed);
    return Scaffold(
      appBar: AppBar(title: const Text('Stáhnout aplikaci')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              if (latest != null || installed != null)
                Card(
                  key: const Key('version-card'),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (latest != null)
                          Text(
                            'Nejnovější verze: ${latest.version}'
                            '${latest.publishedAt == null ? '' : ' (${latest.publishedAt!.toLocal().day}. ${latest.publishedAt!.toLocal().month}. ${latest.publishedAt!.toLocal().year})'}',
                            key: const Key('latest-version'),
                          ),
                        if (installed != null)
                          Text(
                            'Máš nainstalováno: $installed',
                            key: const Key('installed-version'),
                          ),
                        if (outdated)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Je dostupná novější verze. Stáhni ji a nainstaluj přes tu stávající.',
                              key: Key('update-available'),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (latest != null && installed != null && !outdated)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Máš nejnovější verzi.',
                              key: Key('up-to-date'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              FilledButton.icon(
                key: const Key('download-android'),
                onPressed: () => launchUrl(Uri.parse(kAndroidApkUrl)),
                icon: const Icon(Icons.android),
                label: Text(
                  outdated ? 'Aktualizovat pro Android' : 'Stáhnout pro Android',
                ),
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
                        Row(
                          children: [
                            const Icon(Icons.apple),
                            const SizedBox(width: 8),
                            Text(
                              'Instalace na iPhone / iPad',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Otevři tuto stránku v Safari (jiný prohlížeč to neumí).',
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '2. Klepni na tlačítko Sdílet (čtvereček se šipkou nahoru).',
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '3. Vyber „Přidat na plochu“ a potvrď „Přidat“.',
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '4. Rébusárnu pak spustíš ikonou na ploše, jako běžnou aplikaci.',
                        ),
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
