// ============================================================
// Linear-inspired Theme
// ============================================================
// Visual Theme: Ultra-minimal, precise, purple accent
// Atmosphere: Developer tooling, task-oriented, zero clutter
// Inspired by: Linear.app
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #5E6AD2   │ Brand, CTA, active, focus    │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #1C1E3A   │ Subtle primary bg            │
// │ secondary                │ #8B8FB8   │ Muted lavender — depth       │
// │ tertiary                 │ #C084FC   │ Bright purple — sparse glow  │
// │ error                    │ #E5484D   │ Destructive / danger         │
// │ surface                  │ #0D0D10   │ Default surface bg           │
// │ onSurface                │ #EDEDF0   │ Primary text                 │
// │ onSurfaceVariant         │ #808089   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #08080A   │ Deepest void                 │
// │ surfaceContainerLow      │ #0F0F13   │ Low elevation                │
// │ surfaceContainer         │ #15151A   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1C1C22   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #25252D   │ Highest elevation (dialogs)  │
// │ outline                  │ #2E2E36   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Use precise spacing — everything on a 4px grid
//   ✓ Keep surfaces flat, no shadows
//   ✓ Use the purple accent sparingly for focus states only
// Don't:
//   ✗ No gradients, no glows, no decorations
//   ✗ Never use rounded corners above 8px
// ============================================================

import 'package:flutter/material.dart';

const Color _linearSeed = Color(0xFF5E6AD2);

// ============================================================
// Linear — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF5E6AD2),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF1C1E3A),
    onPrimaryContainer: Color(0xFFC9CCF5),
    primaryFixed: Color(0xFFC9CCF5),
    primaryFixedDim: Color(0xFF9598E0),
    secondary: Color(0xFF8B8FB8),
    onSecondary: Color(0xFF1A1B2E),
    secondaryContainer: Color(0xFF22243A),
    onSecondaryContainer: Color(0xFFC9CCF5),
    secondaryFixed: Color(0xFFC9CCF5),
    secondaryFixedDim: Color(0xFF9598E0),
    tertiary: Color(0xFFC084FC),
    onTertiary: Color(0xFF1A0A2E),
    tertiaryContainer: Color(0xFF2E1A4A),
    onTertiaryContainer: Color(0xFFEBD6FF),
    error: Color(0xFFE5484D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3E1316),
    onErrorContainer: Color(0xFFFFD9DF),
    surface: Color(0xFF0D0D10),
    onSurface: Color(0xFFEDEDF0),
    onSurfaceVariant: Color(0xFF808089),
    surfaceContainerLowest: Color(0xFF08080A),
    surfaceContainerLow: Color(0xFF0F0F13),
    surfaceContainer: Color(0xFF15151A),
    surfaceContainerHigh: Color(0xFF1C1C22),
    surfaceContainerHighest: Color(0xFF25252D),
    outline: Color(0xFF2E2E36),
    outlineVariant: Color(0xFF1C1C22),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0D0D10),
    surfaceBright: Color(0xFF25252D),
    inverseSurface: Color(0xFFE4E4E7),
    inversePrimary: Color(0xFF3E44A0),
  ),
  scaffoldBackgroundColor: const Color(0xFF0D0D10),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF15151A),
    foregroundColor: Color(0xFFEDEDF0),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5E6AD2),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF5E6AD2),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF15151A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFF2E2E36)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFF5E6AD2), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFFE5484D)),
    ),
  ),
  dividerColor: const Color(0xFF2E2E36),
  dividerTheme: const DividerThemeData(color: Color(0xFF2E2E36), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF15151A),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: Color(0xFF2E2E36)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFEDEDF0)),
    displayMedium: TextStyle(color: Color(0xFFEDEDF0)),
    displaySmall: TextStyle(color: Color(0xFFEDEDF0)),
    headlineLarge: TextStyle(color: Color(0xFFEDEDF0)),
    headlineMedium: TextStyle(color: Color(0xFFEDEDF0)),
    headlineSmall: TextStyle(color: Color(0xFFEDEDF0)),
    titleLarge: TextStyle(color: Color(0xFFEDEDF0)),
    titleMedium: TextStyle(color: Color(0xFFEDEDF0)),
    titleSmall: TextStyle(color: Color(0xFFEDEDF0)),
    bodyLarge: TextStyle(color: Color(0xFFEDEDF0)),
    bodyMedium: TextStyle(color: Color(0xFF808089)),
    bodySmall: TextStyle(color: Color(0xFF5E5E66)),
    labelLarge: TextStyle(color: Color(0xFFEDEDF0)),
    labelMedium: TextStyle(color: Color(0xFF808089)),
    labelSmall: TextStyle(color: Color(0xFF5E5E66)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF5E6AD2),
    unselectedLabelColor: Color(0xFF808089),
    indicatorColor: Color(0xFF5E6AD2),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF5E6AD2);
      return const Color(0xFF808089);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF2E2E50);
      return const Color(0xFF2E2E36);
    }),
  ),
);

// ============================================================
// Linear — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF4C51BF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8E9FF),
    onPrimaryContainer: Color(0xFF0F1130),
    primaryFixed: Color(0xFFE8E9FF),
    primaryFixedDim: Color(0xFFC5C7F5),
    secondary: Color(0xFF5E5E8A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E0F5),
    onSecondaryContainer: Color(0xFF1A1B2E),
    secondaryFixed: Color(0xFFE0E0F5),
    secondaryFixedDim: Color(0xFFC5C7F5),
    tertiary: Color(0xFF7B2FD4),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEBD6FF),
    onTertiaryContainer: Color(0xFF1A0A2E),
    error: Color(0xFFCF3136),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF3E1316),
    surface: Color(0xFFFAFAFB),
    onSurface: Color(0xFF15151A),
    onSurfaceVariant: Color(0xFF54545E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2F2F5),
    surfaceContainer: Color(0xFFEBEBF0),
    surfaceContainerHigh: Color(0xFFE5E5EA),
    surfaceContainerHighest: Color(0xFFDFDFE5),
    outline: Color(0xFFD4D4DC),
    outlineVariant: Color(0xFFDFDFE5),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDFDFE5),
    surfaceBright: Color(0xFFFAFAFB),
    inverseSurface: Color(0xFF25252D),
    inversePrimary: Color(0xFF989BDF),
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFAFB),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEBEBF0),
    foregroundColor: Color(0xFF15151A),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4C51BF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFEBEBF0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFFD4D4DC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFF4C51BF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFFCF3136)),
    ),
  ),
  dividerColor: const Color(0xFFD4D4DC),
  dividerTheme: const DividerThemeData(color: Color(0xFFD4D4DC), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFEBEBF0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: Color(0xFFD4D4DC)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF15151A)),
    displayMedium: TextStyle(color: Color(0xFF15151A)),
    displaySmall: TextStyle(color: Color(0xFF15151A)),
    headlineLarge: TextStyle(color: Color(0xFF15151A)),
    headlineMedium: TextStyle(color: Color(0xFF15151A)),
    headlineSmall: TextStyle(color: Color(0xFF15151A)),
    titleLarge: TextStyle(color: Color(0xFF15151A)),
    titleMedium: TextStyle(color: Color(0xFF15151A)),
    titleSmall: TextStyle(color: Color(0xFF15151A)),
    bodyLarge: TextStyle(color: Color(0xFF15151A)),
    bodyMedium: TextStyle(color: Color(0xFF54545E)),
    bodySmall: TextStyle(color: Color(0xFF6E6E78)),
    labelLarge: TextStyle(color: Color(0xFF15151A)),
    labelMedium: TextStyle(color: Color(0xFF54545E)),
    labelSmall: TextStyle(color: Color(0xFF6E6E78)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF4C51BF),
    unselectedLabelColor: Color(0xFF54545E),
    indicatorColor: Color(0xFF4C51BF),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF4C51BF);
      return const Color(0xFF808089);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFC5C7F5);
      return const Color(0xFFD4D4DC);
    }),
  ),
);
