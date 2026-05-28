// ============================================================
// Apple-inspired Theme
// ============================================================
// Visual Theme: Premium white space, SF aesthetic, cinematic imagery
// Atmosphere: Consumer electronics, luxury, precision
// Inspired by: Apple
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #0071E3   │ Apple Blue, CTA, active      │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #D6E8FF   │ Subtle blue bg               │
// │ secondary                │ #86868B   │ Muted gray — depth           │
// │ tertiary                 │ #5E5CE6   │ Purple accent — sparse       │
// │ error                    │ #FF3B30   │ Destructive / danger         │
// │ surface                  │ #FFFFFF   │ Default surface bg           │
// │ onSurface                │ #1D1D1F   │ Primary text                 │
// │ onSurfaceVariant         │ #86868B   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #F5F5F7   │ Lowest elevation             │
// │ surfaceContainerLow      │ #EDEDEF   │ Low elevation                │
// │ surfaceContainer         │ #E5E5EA   │ Card / input bg              │
// │ surfaceContainerHigh     │ #DCDCDF   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #D2D2D7   │ Highest elevation (dialogs)  │
// │ outline                  │ #C7C7CC   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Generous whitespace — let content breathe
//   ✓ Large display type with tight letter-spacing
//   ✓ Smooth 12-18px radii, subtle blur shadows
// Don't:
//   ✗ No heavy borders — use elevation instead
//   ✗ Never crowd elements together
// ============================================================

import 'package:flutter/material.dart';

const Color _appleSeed = Color(0xFF0071E3);

// ============================================================
// Apple — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Robot',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2997FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF003573),
    onPrimaryContainer: Color(0xFFB3D4FF),
    primaryFixed: Color(0xFFB3D4FF),
    primaryFixedDim: Color(0xFF70B8FF),

    secondary: Color(0xFF98989D),
    onSecondary: Color(0xFF1D1D1F),
    secondaryContainer: Color(0xFF2C2C2E),
    onSecondaryContainer: Color(0xFFD2D2D7),
    secondaryFixed: Color(0xFFD2D2D7),
    secondaryFixedDim: Color(0xFF98989D),

    tertiary: Color(0xFF8E8CFF),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF201C5E),
    onTertiaryContainer: Color(0xFFCFC8FF),

    error: Color(0xFFFF453A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0004),
    onErrorContainer: Color(0xFFFFDAD6),

    surface: Color(0xFF000000),
    onSurface: Color(0xFFF5F5F7),
    onSurfaceVariant: Color(0xFF98989D),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    surfaceContainerLow: Color(0xFF111111),
    surfaceContainer: Color(0xFF1C1C1E),
    surfaceContainerHigh: Color(0xFF2C2C2E),
    surfaceContainerHighest: Color(0xFF3A3A3C),

    outline: Color(0xFF3A3A3C),
    outlineVariant: Color(0xFF2C2C2E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF3A3A3C),
    inverseSurface: Color(0xFFF5F5F7),
    inversePrimary: Color(0xFF0055B3),
  ),
  scaffoldBackgroundColor: const Color(0xFF000000),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1C1C1E),
    foregroundColor: Color(0xFFF5F5F7),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2997FF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF2997FF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1C1C1E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFF3A3A3C)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFF2997FF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFFF453A)),
    ),
  ),

  dividerColor: const Color(0xFF3A3A3C),
  dividerTheme: const DividerThemeData(color: Color(0xFF3A3A3C), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFF1C1C1E),
    elevation: 2,
    shadowColor: Colors.black54,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide.none,
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFF5F5F7), fontWeight: FontWeight.w600, letterSpacing: -0.5),
    displayMedium: TextStyle(color: Color(0xFFF5F5F7), fontWeight: FontWeight.w600, letterSpacing: -0.5),
    displaySmall: TextStyle(color: Color(0xFFF5F5F7), fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(color: Color(0xFFF5F5F7), fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: Color(0xFFF5F5F7), fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(color: Color(0xFFF5F5F7), fontWeight: FontWeight.w500),
    titleLarge: TextStyle(color: Color(0xFFF5F5F7), fontWeight: FontWeight.w500),
    titleMedium: TextStyle(color: Color(0xFFF5F5F7)),
    titleSmall: TextStyle(color: Color(0xFFF5F5F7)),
    bodyLarge: TextStyle(color: Color(0xFFF5F5F7)),
    bodyMedium: TextStyle(color: Color(0xFF98989D)),
    bodySmall: TextStyle(color: Color(0xFF6D6D72)),
    labelLarge: TextStyle(color: Color(0xFFF5F5F7)),
    labelMedium: TextStyle(color: Color(0xFF98989D)),
    labelSmall: TextStyle(color: Color(0xFF6D6D72)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF2997FF),
    unselectedLabelColor: Color(0xFF98989D),
    indicatorColor: Color(0xFF2997FF),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF2997FF);
      return const Color(0xFF98989D);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF004C99);
      return const Color(0xFF3A3A3C);
    }),
  ),
);

// ============================================================
// Apple — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0071E3),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E8FF),
    onPrimaryContainer: Color(0xFF001A3A),
    primaryFixed: Color(0xFFD6E8FF),
    primaryFixedDim: Color(0xFF99C8FF),

    secondary: Color(0xFF86868B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDEDEF),
    onSecondaryContainer: Color(0xFF1D1D1F),
    secondaryFixed: Color(0xFFEDEDEF),
    secondaryFixedDim: Color(0xFFD2D2D7),

    tertiary: Color(0xFF5E5CE6),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE8E5FF),
    onTertiaryContainer: Color(0xFF120D3A),

    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF4A0004),

    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1D1D1F),
    onSurfaceVariant: Color(0xFF86868B),
    surfaceContainerLowest: Color(0xFFF5F5F7),
    surfaceContainerLow: Color(0xFFEDEDEF),
    surfaceContainer: Color(0xFFE5E5EA),
    surfaceContainerHigh: Color(0xFFDCDCDF),
    surfaceContainerHighest: Color(0xFFD2D2D7),

    outline: Color(0xFFC7C7CC),
    outlineVariant: Color(0xFFD2D2D7),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFD2D2D7),
    surfaceBright: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF3A3A3C),
    inversePrimary: Color(0xFF70B8FF),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F7),
    foregroundColor: Color(0xFF1D1D1F),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0071E3),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF5F5F7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFC7C7CC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFF0071E3), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),

  dividerColor: const Color(0xFFC7C7CC),
  dividerTheme: const DividerThemeData(color: Color(0xFFC7C7CC), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFFFFFFFF),
    elevation: 2,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide.none,
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w600, letterSpacing: -0.5),
    displayMedium: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w600, letterSpacing: -0.5),
    displaySmall: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w500),
    headlineSmall: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w500),
    titleLarge: TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.w500),
    titleMedium: TextStyle(color: Color(0xFF1D1D1F)),
    titleSmall: TextStyle(color: Color(0xFF1D1D1F)),
    bodyLarge: TextStyle(color: Color(0xFF1D1D1F)),
    bodyMedium: TextStyle(color: Color(0xFF86868B)),
    bodySmall: TextStyle(color: Color(0xFFA1A1A6)),
    labelLarge: TextStyle(color: Color(0xFF1D1D1F)),
    labelMedium: TextStyle(color: Color(0xFF86868B)),
    labelSmall: TextStyle(color: Color(0xFFA1A1A6)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF0071E3),
    unselectedLabelColor: Color(0xFF86868B),
    indicatorColor: Color(0xFF0071E3),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF0071E3);
      return const Color(0xFF86868B);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF99C8FF);
      return const Color(0xFFC7C7CC);
    }),
  ),
);
