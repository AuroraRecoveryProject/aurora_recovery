// ============================================================
// Coinbase-inspired Theme
// ============================================================
// Visual Theme: Clean blue identity, trust-focused, institutional feel
// Atmosphere: Crypto exchange, secure, professional
// Inspired by: Coinbase
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #0052FF   │ Coinbase Blue, CTA, active   │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #001A50   │ Subtle blue bg               │
// │ secondary                │ #68809B   │ Steel blue — depth           │
// │ tertiary                 │ #4DA8FF   │ Bright blue — sparse         │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ surface                  │ #0A0E16   │ Default surface bg           │
// │ onSurface                │ #E8ECF2   │ Primary text                 │
// │ onSurfaceVariant         │ #7A8B9E   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #050810   │ Deepest void                 │
// │ surfaceContainerLow      │ #0A0E16   │ Low elevation                │
// │ surfaceContainer         │ #101520   │ Card / input bg              │
// │ surfaceContainerHigh     │ #161C2A   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #1E2535   │ Highest elevation (dialogs)  │
// │ outline                  │ #252D3D   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Trustworthy, institutional blue — serious and professional
//   ✓ Clean card layouts with clear hierarchy
//   ✓ Blue reserved for CTAs and trust signals
// Don't:
//   ✗ No playful elements — this is a financial institution
//   ✗ Don't overuse blue — let white/negative space dominate
// ============================================================

import 'package:flutter/material.dart';

const Color _coinbaseSeed = Color(0xFF0052FF);

// ============================================================
// Coinbase — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF0052FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF001A50),
    onPrimaryContainer: Color(0xFFB3CCFF),
    primaryFixed: Color(0xFFB3CCFF),
    primaryFixedDim: Color(0xFF4DA8FF),
    secondary: Color(0xFF68809B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF161C2A),
    onSecondaryContainer: Color(0xFFBCCDE0),
    secondaryFixed: Color(0xFFBCCDE0),
    secondaryFixedDim: Color(0xFF8EA5C0),
    tertiary: Color(0xFF4DA8FF),
    onTertiary: Color(0xFF001A50),
    tertiaryContainer: Color(0xFF002D80),
    onTertiaryContainer: Color(0xFFB3CCFF),
    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),
    surface: Color(0xFF0A0E16),
    onSurface: Color(0xFFE8ECF2),
    onSurfaceVariant: Color(0xFF7A8B9E),
    surfaceContainerLowest: Color(0xFF050810),
    surfaceContainerLow: Color(0xFF0A0E16),
    surfaceContainer: Color(0xFF101520),
    surfaceContainerHigh: Color(0xFF161C2A),
    surfaceContainerHighest: Color(0xFF1E2535),
    outline: Color(0xFF252D3D),
    outlineVariant: Color(0xFF161C2A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0A0E16),
    surfaceBright: Color(0xFF1E2535),
    inverseSurface: Color(0xFFE8ECF2),
    inversePrimary: Color(0xFF0038B3),
  ),
  scaffoldBackgroundColor: const Color(0xFF0A0E16),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF101520),
    foregroundColor: Color(0xFFE8ECF2),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0052FF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF0052FF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF101520),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF252D3D)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF0052FF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),
  dividerColor: const Color(0xFF252D3D),
  dividerTheme: const DividerThemeData(color: Color(0xFF252D3D), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF101520),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFF252D3D)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFE8ECF2), fontWeight: FontWeight.w500),
    displayMedium: TextStyle(color: Color(0xFFE8ECF2), fontWeight: FontWeight.w500),
    displaySmall: TextStyle(color: Color(0xFFE8ECF2)),
    headlineLarge: TextStyle(color: Color(0xFFE8ECF2)),
    headlineMedium: TextStyle(color: Color(0xFFE8ECF2)),
    headlineSmall: TextStyle(color: Color(0xFFE8ECF2)),
    titleLarge: TextStyle(color: Color(0xFFE8ECF2)),
    titleMedium: TextStyle(color: Color(0xFFE8ECF2)),
    titleSmall: TextStyle(color: Color(0xFFE8ECF2)),
    bodyLarge: TextStyle(color: Color(0xFFE8ECF2)),
    bodyMedium: TextStyle(color: Color(0xFF7A8B9E)),
    bodySmall: TextStyle(color: Color(0xFF556680)),
    labelLarge: TextStyle(color: Color(0xFFE8ECF2)),
    labelMedium: TextStyle(color: Color(0xFF7A8B9E)),
    labelSmall: TextStyle(color: Color(0xFF556680)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF0052FF),
    unselectedLabelColor: Color(0xFF7A8B9E),
    indicatorColor: Color(0xFF0052FF),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF0052FF);
      return const Color(0xFF7A8B9E);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF002D80);
      return const Color(0xFF252D3D);
    }),
  ),
);

// ============================================================
// Coinbase — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0038B3),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4E0FF),
    onPrimaryContainer: Color(0xFF001A50),
    primaryFixed: Color(0xFFD4E0FF),
    primaryFixedDim: Color(0xFF99BFFF),
    secondary: Color(0xFF506680),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD4DEE8),
    onSecondaryContainer: Color(0xFF101520),
    secondaryFixed: Color(0xFFD4DEE8),
    secondaryFixedDim: Color(0xFFBCCDE0),
    tertiary: Color(0xFF0052FF),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB3CCFF),
    onTertiaryContainer: Color(0xFF001A50),
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),
    surface: Color(0xFFF2F4F8),
    onSurface: Color(0xFF101520),
    onSurfaceVariant: Color(0xFF4A5A6E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEDF0F5),
    surfaceContainer: Color(0xFFE5E9F0),
    surfaceContainerHigh: Color(0xFFDEE2EA),
    surfaceContainerHighest: Color(0xFFD8DCE5),
    outline: Color(0xFFC0C8D4),
    outlineVariant: Color(0xFFD8DCE5),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFD8DCE5),
    surfaceBright: Color(0xFFF2F4F8),
    inverseSurface: Color(0xFF1E2535),
    inversePrimary: Color(0xFF4DA8FF),
  ),
  scaffoldBackgroundColor: const Color(0xFFF2F4F8),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFE5E9F0),
    foregroundColor: Color(0xFF101520),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0038B3),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFE5E9F0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFC0C8D4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF0038B3), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),
  dividerColor: const Color(0xFFC0C8D4),
  dividerTheme: const DividerThemeData(color: Color(0xFFC0C8D4), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFE5E9F0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFC0C8D4)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF101520), fontWeight: FontWeight.w500),
    displayMedium: TextStyle(color: Color(0xFF101520), fontWeight: FontWeight.w500),
    displaySmall: TextStyle(color: Color(0xFF101520)),
    headlineLarge: TextStyle(color: Color(0xFF101520)),
    headlineMedium: TextStyle(color: Color(0xFF101520)),
    headlineSmall: TextStyle(color: Color(0xFF101520)),
    titleLarge: TextStyle(color: Color(0xFF101520)),
    titleMedium: TextStyle(color: Color(0xFF101520)),
    titleSmall: TextStyle(color: Color(0xFF101520)),
    bodyLarge: TextStyle(color: Color(0xFF101520)),
    bodyMedium: TextStyle(color: Color(0xFF4A5A6E)),
    bodySmall: TextStyle(color: Color(0xFF6B7A90)),
    labelLarge: TextStyle(color: Color(0xFF101520)),
    labelMedium: TextStyle(color: Color(0xFF4A5A6E)),
    labelSmall: TextStyle(color: Color(0xFF6B7A90)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF0038B3),
    unselectedLabelColor: Color(0xFF4A5A6E),
    indicatorColor: Color(0xFF0038B3),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF0038B3);
      return const Color(0xFF7A8B9E);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF99BFFF);
      return const Color(0xFFC0C8D4);
    }),
  ),
);
