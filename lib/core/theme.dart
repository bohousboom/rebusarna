import 'package:flutter/material.dart';

const _seed = Color(0xFF3F51B5);

/// Barvy obtížnosti: 1 tyrkysová, 2 žlutá, 3 červená.
Color difficultyColor(int difficulty) => switch (difficulty) {
      1 => const Color(0xFF1ABC9C),
      2 => const Color(0xFFF1C40F),
      _ => const Color(0xFFE74C3C),
    };

/// Slovní popis obtížnosti.
String difficultyLabel(int difficulty) => switch (difficulty) {
      1 => 'lehká',
      2 => 'střední',
      _ => 'těžká',
    };

ThemeData _build(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

final ThemeData lightTheme = _build(Brightness.light);
final ThemeData darkTheme = _build(Brightness.dark);
