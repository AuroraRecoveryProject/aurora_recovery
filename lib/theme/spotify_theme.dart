// ============================================================
// Spotify-inspired Theme
// ============================================================
// Visual Theme: Vibrant green on deep dark, bold typography
// Atmosphere: Album-art-driven, immersive, high-contrast
// Inspired by: Spotify
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #1DB954   │ Brand green, CTA, active     │
// │ onPrimary                │ #000000   │ Text / icons on primary      │
// │ primaryContainer         │ #003E1A   │ Subtle green bg              │
// │ secondary                │ #1A1A1A   │ Card surfaces                │
// │ tertiary                 │ #B3B3B3   │ Muted text / secondary info  │
// │ error                    │ #E91429   │ Destructive / danger         │
// │ surface                  │ #121212   │ Default surface bg           │
// │ onSurface                │ #FFFFFF   │ Primary text                 │
// │ onSurfaceVariant         │ #B3B3B3   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #000000   │ Deepest black                │
// │ surfaceContainerLow      │ #0A0A0A   │ Low elevation                │
// │ surfaceContainer         │ #181818   │ Card / input bg              │
// │ surfaceContainerHigh     │ #282828   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #333333   │ Highest elevation (dialogs)  │
// │ outline                  │ #333333   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Use bold weights for headings — make a statement
//   ✓ High contrast text on deep black surfaces
//   ✓ Green ONLY for primary actions and active states
// Don't:
//   ✗ Don't tint surfaces — keep them pure black/gray
//   ✗ No muted green variants — green must pop
// ============================================================

import 'package:flutter/material.dart';

const Color _spotifySeed = Color(0xFF1DB954);

// ============================================================
// Spotify — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF1DB954),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF003E1A),
    onPrimaryContainer: Color(0xFF7BFFA0),
    primaryFixed: Color(0xFF7BFFA0),
    primaryFixedDim: Color(0xFF1DB954),
    secondary: Color(0xFF1A1A1A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF282828),
    onSecondaryContainer: Color(0xFFB3B3B3),
    secondaryFixed: Color(0xFF282828),
    secondaryFixedDim: Color(0xFF333333),
    tertiary: Color(0xFFB3B3B3),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF333333),
    onTertiaryContainer: Color(0xFFF0F0F0),
    error: Color(0xFFE91429),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF45000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFB3B3B3),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFF181818),
    surfaceContainerHigh: Color(0xFF282828),
    surfaceContainerHighest: Color(0xFF333333),
    outline: Color(0xFF333333),
    outlineVariant: Color(0xFF282828),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF121212),
    surfaceBright: Color(0xFF333333),
    inverseSurface: Color(0xFFE0E0E0),
    inversePrimary: Color(0xFF169C46),
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF181818),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1DB954),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF1DB954),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF282828),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF333333)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF1DB954), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFE91429)),
    ),
  ),
  dividerColor: const Color(0xFF333333),
  dividerTheme: const DividerThemeData(color: Color(0xFF333333), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF181818),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide.none,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900),
    displayMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w900),
    displaySmall: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Color(0xFFFFFFFF)),
    bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
    bodyMedium: TextStyle(color: Color(0xFFB3B3B3)),
    bodySmall: TextStyle(color: Color(0xFF727272)),
    labelLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFFB3B3B3)),
    labelSmall: TextStyle(color: Color(0xFF727272)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF1DB954),
    unselectedLabelColor: Color(0xFFB3B3B3),
    indicatorColor: Color(0xFF1DB954),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF1DB954);
      return const Color(0xFFB3B3B3);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF003E1A);
      return const Color(0xFF333333);
    }),
  ),
);

// ============================================================
// Spotify — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF169C46),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF7BFFA0),
    onPrimaryContainer: Color(0xFF003E1A),
    primaryFixed: Color(0xFF7BFFA0),
    primaryFixedDim: Color(0xFF1DB954),
    secondary: Color(0xFFF0F0F0),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFFE0E0E0),
    onSecondaryContainer: Color(0xFF333333),
    secondaryFixed: Color(0xFFE0E0E0),
    secondaryFixedDim: Color(0xFFD0D0D0),
    tertiary: Color(0xFF727272),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0E0E0),
    onTertiaryContainer: Color(0xFF333333),
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF45000A),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    onSurfaceVariant: Color(0xFF727272),
    surfaceContainerLowest: Color(0xFFFAFAFA),
    surfaceContainerLow: Color(0xFFF5F5F5),
    surfaceContainer: Color(0xFFF0F0F0),
    surfaceContainerHigh: Color(0xFFEBEBEB),
    surfaceContainerHighest: Color(0xFFE5E5E5),
    outline: Color(0xFFD0D0D0),
    outlineVariant: Color(0xFFE5E5E5),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFE5E5E5),
    surfaceBright: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF333333),
    inversePrimary: Color(0xFF1DB954),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF0F0F0),
    foregroundColor: Color(0xFF000000),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF169C46),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF0F0F0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFD0D0D0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF169C46), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),
  dividerColor: const Color(0xFFD0D0D0),
  dividerTheme: const DividerThemeData(color: Color(0xFFD0D0D0), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFF0F0F0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide.none,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w900),
    displayMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w900),
    displaySmall: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: Color(0xFF000000)),
    bodyLarge: TextStyle(color: Color(0xFF000000)),
    bodyMedium: TextStyle(color: Color(0xFF727272)),
    bodySmall: TextStyle(color: Color(0xFF999999)),
    labelLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFF727272)),
    labelSmall: TextStyle(color: Color(0xFF999999)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF169C46),
    unselectedLabelColor: Color(0xFF727272),
    indicatorColor: Color(0xFF169C46),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF169C46);
      return const Color(0xFF727272);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF1DB954);
      return const Color(0xFFD0D0D0);
    }),
  ),
);
