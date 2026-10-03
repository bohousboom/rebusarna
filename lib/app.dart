import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'presentation/shared/splash_screen.dart';

class RebusarnaApp extends StatefulWidget {
  const RebusarnaApp({super.key});

  @override
  State<RebusarnaApp> createState() => _RebusarnaAppState();
}

class _RebusarnaAppState extends State<RebusarnaApp> {
  final _router = buildRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: kAppName,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) =>
            SplashOverlay(child: child ?? const SizedBox.shrink()),
      );
}
