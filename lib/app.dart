import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'presentation/shared/splash_screen.dart';

class RebusarnaApp extends ConsumerStatefulWidget {
  const RebusarnaApp({super.key});

  @override
  ConsumerState<RebusarnaApp> createState() => _RebusarnaAppState();
}

class _RebusarnaAppState extends ConsumerState<RebusarnaApp> {
  final _router = buildRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: kAppName,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ref.watch(themeModeProvider),
        routerConfig: _router,
        builder: (context, child) =>
            SplashOverlay(child: child ?? const SizedBox.shrink()),
      );
}
