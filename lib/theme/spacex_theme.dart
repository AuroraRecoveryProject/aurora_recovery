// ============================================================
// SpaceX-inspired Theme
// ============================================================
// Visual Theme: Stark black and white, full-bleed imagery, futuristic
// Atmosphere: Space technology, engineering, bold
// Inspired by: SpaceX
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #FFFFFF   │ Brand white, CTA (on dark)   │
// │ onPrimary                │ #000000   │ Text / icons on primary      │
// │ primaryContainer         │ #1A1A1A   │ Subtle bg                    │
// │ secondary                │ #888888   │ Steel gray — depth           │
// │ tertiary                 │ #0055A4   │ Blue accent — sparse         │
// │ error                    │ #FF3333   │ Destructive / danger         │
// │ surface                  │ #000000   │ Default surface bg           │
// │ onSurface                │ #FFFFFF   │ Primary text                 │
// │ onSurfaceVariant         │ #888888   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #050505   │ Deepest void                 │
// │ surfaceContainerLow      │ #0A0A0A   │ Low elevation                │
// │ surfaceContainer         │ #111111   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1A1A1A   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #242424   │ Highest elevation (dialogs)  │
// │ outline                  │ #2A2A2A   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Extreme contrast — pure black and pure white
//   ✓ Bold, uppercase type for headings
//   ✓ Generous whitespace, full-viewport layouts
// Don't:
//   ✗ No gray text on black — must be legible
//   ✗ Avoid round corners — angular and sharp
// ============================================================

import 'package:flutter/material.dart';

const Color _spacexSeed = Color(0xFFFFFFFF);

// ============================================================
// SpaceX — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF1A1A1A),
    onPrimaryContainer: Color(0xFFD4D4D4),
    primaryFixed: Color(0xFFD4D4D4),
    primaryFixedDim: Color(0xFFB0B0B0),
    secondary: Color(0xFF888888),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF1A1A1A),
    onSecondaryContainer: Color(0xFFCCCCCC),
    secondaryFixed: Color(0xFFCCCCCC),
    secondaryFixedDim: Color(0xFFA0A0A0),
    tertiary: Color(0xFF0055A4),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF001A3A),
    onTertiaryContainer: Color(0xFF99CCFF),
    error: Color(0xFFFF3333),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3E0000),
    onErrorContainer: Color(0xFFFFCDD2),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF888888),
    surfaceContainerLowest: Color(0xFF050505),
    surfaceContainerLow: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFF121212),
    surfaceContainerHigh: Color(0xFF1A1A1A),
    surfaceContainerHighest: Color(0xFF242424),
    outline: Color(0xFF2A2A2A),
    outlineVariant: Color(0xFF1A1A1A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF242424),
    inverseSurface: Color(0xFFD4D4D4),
    inversePrimary: Color(0xFF000000),
  ),
  scaffoldBackgroundColor: const Color(0xFF000000),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF121212),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFF2A2A2A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFFFFFFFF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFFFF3333)),
    ),
  ),
  dividerColor: const Color(0xFF2A2A2A),
  dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF121212),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: const BorderSide(color: Color(0xFF2A2A2A)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
    displayMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
    displaySmall: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: Color(0xFFFFFFFF)),
    headlineSmall: TextStyle(color: Color(0xFFFFFFFF)),
    titleLarge: TextStyle(color: Color(0xFFFFFFFF)),
    titleMedium: TextStyle(color: Color(0xFFFFFFFF)),
    titleSmall: TextStyle(color: Color(0xFFFFFFFF)),
    bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
    bodyMedium: TextStyle(color: Color(0xFF888888)),
    bodySmall: TextStyle(color: Color(0xFF666666)),
    labelLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFF888888)),
    labelSmall: TextStyle(color: Color(0xFF666666)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFFFFFFF),
    unselectedLabelColor: Color(0xFF888888),
    indicatorColor: Color(0xFFFFFFFF),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFFFFFF);
      return const Color(0xFF888888);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF333333);
      return const Color(0xFF242424);
    }),
  ),
);

// ============================================================
// SpaceX — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE5E5E5),
    onPrimaryContainer: Color(0xFF1A1A1A),
    primaryFixed: Color(0xFFE5E5E5),
    primaryFixedDim: Color(0xFFD4D4D4),
    secondary: Color(0xFF606060),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE5E5E5),
    onSecondaryContainer: Color(0xFF1A1A1A),
    secondaryFixed: Color(0xFFE5E5E5),
    secondaryFixedDim: Color(0xFFD4D4D4),
    tertiary: Color(0xFF0055A4),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB3D4FF),
    onTertiaryContainer: Color(0xFF001A3A),
    error: Color(0xFFCC0000),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFF3E0000),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    onSurfaceVariant: Color(0xFF606060),
    surfaceContainerLowest: Color(0xFFF5F5F5),
    surfaceContainerLow: Color(0xFFEDEDED),
    surfaceContainer: Color(0xFFE5E5E5),
    surfaceContainerHigh: Color(0xFFDCDCDC),
    surfaceContainerHighest: Color(0xFFD4D4D4),
    outline: Color(0xFFCCCCCC),
    outlineVariant: Color(0xFFD4D4D4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFD4D4D4),
    surfaceBright: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF242424),
    inversePrimary: Color(0xFFD4D4D4),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F5),
    foregroundColor: Color(0xFF000000),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF000000),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFFCCCCCC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFF000000), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFFCC0000)),
    ),
  ),
  dividerColor: const Color(0xFFCCCCCC),
  dividerTheme: const DividerThemeData(color: Color(0xFFCCCCCC), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFF5F5F5),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w700),
    displayMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w700),
    displaySmall: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: Color(0xFF000000)),
    headlineSmall: TextStyle(color: Color(0xFF000000)),
    titleLarge: TextStyle(color: Color(0xFF000000)),
    titleMedium: TextStyle(color: Color(0xFF000000)),
    titleSmall: TextStyle(color: Color(0xFF000000)),
    bodyLarge: TextStyle(color: Color(0xFF000000)),
    bodyMedium: TextStyle(color: Color(0xFF606060)),
    bodySmall: TextStyle(color: Color(0xFF808080)),
    labelLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFF606060)),
    labelSmall: TextStyle(color: Color(0xFF808080)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF000000),
    unselectedLabelColor: Color(0xFF606060),
    indicatorColor: Color(0xFF000000),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF000000);
      return const Color(0xFF606060);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFD4D4D4);
      return const Color(0xFFCCCCCC);
    }),
  ),
);
