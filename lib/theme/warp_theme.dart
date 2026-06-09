// ============================================================
// Warp-inspired Theme
// ============================================================
// Visual Theme: Dark IDE-like interface, block-based command UI
// Atmosphere: Modern terminal, developer tooling, sleek
// Inspired by: Warp
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #01E0FF   │ Electric cyan, CTA, active   │
// │ onPrimary                │ #001A1F   │ Text / icons on primary      │
// │ primaryContainer         │ #003540   │ Subtle cyan bg               │
// │ secondary                │ #6C6C7A   │ Slate — depth                │
// │ tertiary                 │ #7B61FF   │ Purple accent — sparse       │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ surface                  │ #0C0C11   │ Default surface bg           │
// │ onSurface                │ #E4E4EC   │ Primary text                 │
// │ onSurfaceVariant         │ #8A8A98   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #06060A   │ Deepest void                 │
// │ surfaceContainerLow      │ #0C0C11   │ Low elevation                │
// │ surfaceContainer         │ #14141C   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1C1C26   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #252530   │ Highest elevation (dialogs)  │
// │ outline                  │ #2E2E3A   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Block-based layouts — distinct surface blocks
//   ✓ Monospace for terminal/code areas
//   ✓ Cyan for focus states and active command line
// Don't:
//   ✗ Don't use cyan for decorative purposes — reserved for input/focus
//   ✗ Avoid rounded corners above 8px
// ============================================================

import 'package:flutter/material.dart';

const Color _warpSeed = Color(0xFF01E0FF);

// ============================================================
// Warp — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF01E0FF),
    onPrimary: Color(0xFF001A1F),
    primaryContainer: Color(0xFF003540),
    onPrimaryContainer: Color(0xFFB3F0FF),
    primaryFixed: Color(0xFFB3F0FF),
    primaryFixedDim: Color(0xFF4DE8FF),
    secondary: Color(0xFF6C6C7A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF252530),
    onSecondaryContainer: Color(0xFFB8B8C4),
    secondaryFixed: Color(0xFFB8B8C4),
    secondaryFixedDim: Color(0xFF8A8A98),
    tertiary: Color(0xFF7B61FF),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF1C1060),
    onTertiaryContainer: Color(0xFFCFC8FF),
    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),
    surface: Color(0xFF0C0C11),
    onSurface: Color(0xFFE4E4EC),
    onSurfaceVariant: Color(0xFF8A8A98),
    surfaceContainerLowest: Color(0xFF06060A),
    surfaceContainerLow: Color(0xFF0C0C11),
    surfaceContainer: Color(0xFF14141C),
    surfaceContainerHigh: Color(0xFF1C1C26),
    surfaceContainerHighest: Color(0xFF252530),
    outline: Color(0xFF2E2E3A),
    outlineVariant: Color(0xFF1C1C26),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0C0C11),
    surfaceBright: Color(0xFF252530),
    inverseSurface: Color(0xFFE4E4EC),
    inversePrimary: Color(0xFF0099B0),
  ),
  scaffoldBackgroundColor: const Color(0xFF0C0C11),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF14141C),
    foregroundColor: Color(0xFFE4E4EC),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF01E0FF),
      foregroundColor: const Color(0xFF001A1F),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF01E0FF),
      foregroundColor: const Color(0xFF001A1F),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF14141C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF2E2E3A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF01E0FF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),
  dividerColor: const Color(0xFF2E2E3A),
  dividerTheme: const DividerThemeData(color: Color(0xFF2E2E3A), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF14141C),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFF2E2E3A)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFE4E4EC)),
    displayMedium: TextStyle(color: Color(0xFFE4E4EC)),
    displaySmall: TextStyle(color: Color(0xFFE4E4EC)),
    headlineLarge: TextStyle(color: Color(0xFFE4E4EC)),
    headlineMedium: TextStyle(color: Color(0xFFE4E4EC)),
    headlineSmall: TextStyle(color: Color(0xFFE4E4EC)),
    titleLarge: TextStyle(color: Color(0xFFE4E4EC)),
    titleMedium: TextStyle(color: Color(0xFFE4E4EC)),
    titleSmall: TextStyle(color: Color(0xFFE4E4EC)),
    bodyLarge: TextStyle(color: Color(0xFFE4E4EC)),
    bodyMedium: TextStyle(color: Color(0xFF8A8A98)),
    bodySmall: TextStyle(color: Color(0xFF666672)),
    labelLarge: TextStyle(color: Color(0xFFE4E4EC)),
    labelMedium: TextStyle(color: Color(0xFF8A8A98)),
    labelSmall: TextStyle(color: Color(0xFF666672)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF01E0FF),
    unselectedLabelColor: Color(0xFF8A8A98),
    indicatorColor: Color(0xFF01E0FF),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF01E0FF);
      return const Color(0xFF8A8A98);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF004050);
      return const Color(0xFF2E2E3A);
    }),
  ),
);

// ============================================================
// Warp — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0099B0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB3F0FF),
    onPrimaryContainer: Color(0xFF001A1F),
    primaryFixed: Color(0xFFB3F0FF),
    primaryFixedDim: Color(0xFF4DE8FF),
    secondary: Color(0xFF5A5A66),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E0E8),
    onSecondaryContainer: Color(0xFF1C1C26),
    secondaryFixed: Color(0xFFE0E0E8),
    secondaryFixedDim: Color(0xFFC8C8D4),
    tertiary: Color(0xFF5A3FD6),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCFC8FF),
    onTertiaryContainer: Color(0xFF1C1060),
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),
    surface: Color(0xFFF5F5FA),
    onSurface: Color(0xFF14141C),
    onSurfaceVariant: Color(0xFF5A5A66),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFEFF4),
    surfaceContainer: Color(0xFFE8E8EE),
    surfaceContainerHigh: Color(0xFFE2E2E8),
    surfaceContainerHighest: Color(0xFFDCDCE2),
    outline: Color(0xFFC8C8CE),
    outlineVariant: Color(0xFFDCDCE2),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDCDCE2),
    surfaceBright: Color(0xFFF5F5FA),
    inverseSurface: Color(0xFF252530),
    inversePrimary: Color(0xFF4DE8FF),
  ),
  scaffoldBackgroundColor: const Color(0xFFF5F5FA),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFE8E8EE),
    foregroundColor: Color(0xFF14141C),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0099B0),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFE8E8EE),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFC8C8CE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF0099B0), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),
  dividerColor: const Color(0xFFC8C8CE),
  dividerTheme: const DividerThemeData(color: Color(0xFFC8C8CE), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFE8E8EE),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFC8C8CE)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF14141C)),
    displayMedium: TextStyle(color: Color(0xFF14141C)),
    displaySmall: TextStyle(color: Color(0xFF14141C)),
    headlineLarge: TextStyle(color: Color(0xFF14141C)),
    headlineMedium: TextStyle(color: Color(0xFF14141C)),
    headlineSmall: TextStyle(color: Color(0xFF14141C)),
    titleLarge: TextStyle(color: Color(0xFF14141C)),
    titleMedium: TextStyle(color: Color(0xFF14141C)),
    titleSmall: TextStyle(color: Color(0xFF14141C)),
    bodyLarge: TextStyle(color: Color(0xFF14141C)),
    bodyMedium: TextStyle(color: Color(0xFF5A5A66)),
    bodySmall: TextStyle(color: Color(0xFF7A7A86)),
    labelLarge: TextStyle(color: Color(0xFF14141C)),
    labelMedium: TextStyle(color: Color(0xFF5A5A66)),
    labelSmall: TextStyle(color: Color(0xFF7A7A86)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF0099B0),
    unselectedLabelColor: Color(0xFF5A5A66),
    indicatorColor: Color(0xFF0099B0),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF0099B0);
      return const Color(0xFF8A8A98);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF4DE8FF);
      return const Color(0xFFC8C8CE);
    }),
  ),
);
