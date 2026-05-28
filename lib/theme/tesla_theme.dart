// ============================================================
// Tesla-inspired Theme
// ============================================================
// Visual Theme: Radical subtraction, cinematic full-viewport photography
// Atmosphere: Electric vehicles, minimalism, future-forward
// Inspired by: Tesla
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #E82127   │ Tesla Red, CTA               │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #3E0004   │ Subtle red bg                │
// │ secondary                │ #888888   │ Steel gray — depth           │
// │ tertiary                 │ #3E6AE1   │ Tesla Blue — sparse accent   │
// │ error                    │ #E82127   │ Destructive / danger         │
// │ surface                  │ #000000   │ Default surface bg           │
// │ onSurface                │ #FFFFFF   │ Primary text                 │
// │ onSurfaceVariant         │ #999999   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #050505   │ Deepest black                │
// │ surfaceContainerLow      │ #0A0A0A   │ Low elevation                │
// │ surfaceContainer         │ #111111   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1A1A1A   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #242424   │ Highest elevation (dialogs)  │
// │ outline                  │ #2A2A2A   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Radical subtraction — remove everything non-essential
//   ✓ Full-viewport hero sections with minimal text
//   ✓ Thin, light font weights for body text
// Don't:
//   ✗ No decorations, no borders unless absolutely necessary
//   ✗ Never crowd — one message per screen
// ============================================================

import 'package:flutter/material.dart';

const Color _teslaSeed = Color(0xFFE82127);

// ============================================================
// Tesla — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Robot',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFE82127),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3E0004),
    onPrimaryContainer: Color(0xFFFFDAD6),
    primaryFixed: Color(0xFFFFDAD6),
    primaryFixedDim: Color(0xFFFF6B6B),

    secondary: Color(0xFF888888),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF1A1A1A),
    onSecondaryContainer: Color(0xFFCCCCCC),
    secondaryFixed: Color(0xFFCCCCCC),
    secondaryFixedDim: Color(0xFFA0A0A0),

    tertiary: Color(0xFF3E6AE1),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF00154A),
    onTertiaryContainer: Color(0xFFB3CCFF),

    error: Color(0xFFE82127),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3E0004),
    onErrorContainer: Color(0xFFFFDAD6),

    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF999999),
    surfaceContainerLowest: Color(0xFF050505),
    surfaceContainerLow: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFF111111),
    surfaceContainerHigh: Color(0xFF1A1A1A),
    surfaceContainerHighest: Color(0xFF242424),

    outline: Color(0xFF2A2A2A),
    outlineVariant: Color(0xFF1A1A1A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF242424),
    inverseSurface: Color(0xFFD4D4D4),
    inversePrimary: Color(0xFFB0101A),
  ),
  scaffoldBackgroundColor: const Color(0xFF000000),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF111111),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE82127),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFE82127),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF111111),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF2A2A2A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFE82127), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFE82127)),
    ),
  ),

  dividerColor: const Color(0xFF2A2A2A),
  dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFF111111),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide.none,
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFFFFFFFF)),
    headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFFFFFFFF)),
    headlineSmall: TextStyle(color: Color(0xFFFFFFFF)),
    titleLarge: TextStyle(color: Color(0xFFFFFFFF)),
    titleMedium: TextStyle(color: Color(0xFFFFFFFF)),
    titleSmall: TextStyle(color: Color(0xFFFFFFFF)),
    bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
    bodyMedium: TextStyle(color: Color(0xFF999999)),
    bodySmall: TextStyle(color: Color(0xFF707070)),
    labelLarge: TextStyle(color: Color(0xFFFFFFFF)),
    labelMedium: TextStyle(color: Color(0xFF999999)),
    labelSmall: TextStyle(color: Color(0xFF707070)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFE82127),
    unselectedLabelColor: Color(0xFF999999),
    indicatorColor: Color(0xFFE82127),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFE82127);
      return const Color(0xFF999999);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF3E0004);
      return const Color(0xFF2A2A2A);
    }),
  ),
);

// ============================================================
// Tesla — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFB0101A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF3E0004),
    primaryFixed: Color(0xFFFFDAD6),
    primaryFixedDim: Color(0xFFFF6B6B),

    secondary: Color(0xFF606060),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE5E5E5),
    onSecondaryContainer: Color(0xFF1A1A1A),
    secondaryFixed: Color(0xFFE5E5E5),
    secondaryFixedDim: Color(0xFFD4D4D4),

    tertiary: Color(0xFF1E4DD4),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD4E0FF),
    onTertiaryContainer: Color(0xFF00154A),

    error: Color(0xFFB0101A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF3E0004),

    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    onSurfaceVariant: Color(0xFF606060),
    surfaceContainerLowest: Color(0xFFF5F5F5),
    surfaceContainerLow: Color(0xFFEDEDED),
    surfaceContainer: Color(0xFFE5E5E5),
    surfaceContainerHigh: Color(0xFFDCDCDC),
    surfaceContainerHighest: Color(0xFFD4D4D4),

    outline: Color(0xFFD4D4D4),
    outlineVariant: Color(0xFFDCDCDC),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFD4D4D4),
    surfaceBright: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF242424),
    inversePrimary: Color(0xFFFF6B6B),
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
      backgroundColor: const Color(0xFFB0101A),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFD4D4D4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFB0101A), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFB0101A)),
    ),
  ),

  dividerColor: const Color(0xFFD4D4D4),
  dividerTheme: const DividerThemeData(color: Color(0xFFD4D4D4), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFFF5F5F5),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide.none,
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFF000000)),
    headlineLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFF000000)),
    headlineSmall: TextStyle(color: Color(0xFF000000)),
    titleLarge: TextStyle(color: Color(0xFF000000)),
    titleMedium: TextStyle(color: Color(0xFF000000)),
    titleSmall: TextStyle(color: Color(0xFF000000)),
    bodyLarge: TextStyle(color: Color(0xFF000000)),
    bodyMedium: TextStyle(color: Color(0xFF606060)),
    bodySmall: TextStyle(color: Color(0xFF808080)),
    labelLarge: TextStyle(color: Color(0xFF000000)),
    labelMedium: TextStyle(color: Color(0xFF606060)),
    labelSmall: TextStyle(color: Color(0xFF808080)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFB0101A),
    unselectedLabelColor: Color(0xFF606060),
    indicatorColor: Color(0xFFB0101A),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFB0101A);
      return const Color(0xFF606060);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFF6B6B);
      return const Color(0xFFD4D4D4);
    }),
  ),
);
