// ============================================================
// NVIDIA-inspired Theme
// ============================================================
// Visual Theme: Green-black energy, technical power aesthetic
// Atmosphere: GPU computing, high-performance, gaming-adjacent
// Inspired by: NVIDIA
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #76B900   │ NVIDIA green, CTA, active    │
// │ onPrimary                │ #000000   │ Text / icons on primary      │
// │ primaryContainer         │ #1A3300   │ Subtle green bg              │
// │ secondary                │ #5E5E5E   │ Gunmetal — depth             │
// │ tertiary                 │ #A4E04A   │ Bright green — sparse glow   │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ surface                  │ #0A0A0A   │ Default surface bg           │
// │ onSurface                │ #E0E0E0   │ Primary text                 │
// │ onSurfaceVariant         │ #808080   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #000000   │ Deepest black                │
// │ surfaceContainerLow      │ #0D0D0D   │ Low elevation                │
// │ surfaceContainer         │ #141414   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1C1C1C   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #262626   │ Highest elevation (dialogs)  │
// │ outline                  │ #2E2E2E   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Green as the power accent — use for CTAs and active states
//   ✓ Sharp, angular design language — right angles preferred
//   ✓ High contrast — black backgrounds, bright text
// Don't:
//   ✗ Don't dilute the green with pastels — keep it bold
//   ✗ No rounded corners — NVIDIA is sharp and angular
// ============================================================

import 'package:flutter/material.dart';

const Color _nvidiaSeed = Color(0xFF76B900);

// ============================================================
// NVIDIA — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF76B900),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF1A3300),
    onPrimaryContainer: Color(0xFFB3FF33),
    primaryFixed: Color(0xFFB3FF33),
    primaryFixedDim: Color(0xFFA4E04A),
    secondary: Color(0xFF5E5E5E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF262626),
    onSecondaryContainer: Color(0xFFB0B0B0),
    secondaryFixed: Color(0xFFB0B0B0),
    secondaryFixedDim: Color(0xFF8A8A8A),
    tertiary: Color(0xFFA4E04A),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF2E4A00),
    onTertiaryContainer: Color(0xFFC8FF66),
    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),
    surface: Color(0xFF0A0A0A),
    onSurface: Color(0xFFE0E0E0),
    onSurfaceVariant: Color(0xFF808080),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0D0D0D),
    surfaceContainer: Color(0xFF141414),
    surfaceContainerHigh: Color(0xFF1C1C1C),
    surfaceContainerHighest: Color(0xFF262626),
    outline: Color(0xFF2E2E2E),
    outlineVariant: Color(0xFF1C1C1C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0A0A0A),
    surfaceBright: Color(0xFF262626),
    inverseSurface: Color(0xFFE0E0E0),
    inversePrimary: Color(0xFF5A8F00),
  ),
  scaffoldBackgroundColor: const Color(0xFF0A0A0A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF141414),
    foregroundColor: Color(0xFFE0E0E0),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF76B900),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF76B900),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF141414),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFF2E2E2E)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFF76B900), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),
  dividerColor: const Color(0xFF2E2E2E),
  dividerTheme: const DividerThemeData(color: Color(0xFF2E2E2E), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF141414),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: const BorderSide(color: Color(0xFF2E2E2E)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w700),
    displayMedium: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w700),
    displaySmall: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: Color(0xFFE0E0E0)),
    headlineSmall: TextStyle(color: Color(0xFFE0E0E0)),
    titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
    titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
    titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
    bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
    bodyMedium: TextStyle(color: Color(0xFF808080)),
    bodySmall: TextStyle(color: Color(0xFF5A5A5A)),
    labelLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFF808080)),
    labelSmall: TextStyle(color: Color(0xFF5A5A5A)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF76B900),
    unselectedLabelColor: Color(0xFF808080),
    indicatorColor: Color(0xFF76B900),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF76B900);
      return const Color(0xFF808080);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF2E4A00);
      return const Color(0xFF2E2E2E);
    }),
  ),
);

// ============================================================
// NVIDIA — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF5A8F00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB3FF33),
    onPrimaryContainer: Color(0xFF1A3300),
    primaryFixed: Color(0xFFB3FF33),
    primaryFixedDim: Color(0xFFA4E04A),
    secondary: Color(0xFF5E5E5E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E0E0),
    onSecondaryContainer: Color(0xFF262626),
    secondaryFixed: Color(0xFFE0E0E0),
    secondaryFixedDim: Color(0xFFCCCCCC),
    tertiary: Color(0xFF6A9F00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC8FF66),
    onTertiaryContainer: Color(0xFF1A3300),
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),
    surface: Color(0xFFF5F5F5),
    onSurface: Color(0xFF141414),
    onSurfaceVariant: Color(0xFF5A5A5A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF0F0F0),
    surfaceContainer: Color(0xFFEBEBEB),
    surfaceContainerHigh: Color(0xFFE5E5E5),
    surfaceContainerHighest: Color(0xFFDFDFDF),
    outline: Color(0xFFCCCCCC),
    outlineVariant: Color(0xFFDFDFDF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDFDFDF),
    surfaceBright: Color(0xFFF5F5F5),
    inverseSurface: Color(0xFF262626),
    inversePrimary: Color(0xFFA4E04A),
  ),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEBEBEB),
    foregroundColor: Color(0xFF141414),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5A8F00),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFEBEBEB),
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
      borderSide: BorderSide(color: Color(0xFF5A8F00), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),
  dividerColor: const Color(0xFFCCCCCC),
  dividerTheme: const DividerThemeData(color: Color(0xFFCCCCCC), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFEBEBEB),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF141414), fontWeight: FontWeight.w700),
    displayMedium: TextStyle(color: Color(0xFF141414), fontWeight: FontWeight.w700),
    displaySmall: TextStyle(color: Color(0xFF141414), fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(color: Color(0xFF141414), fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(color: Color(0xFF141414)),
    headlineSmall: TextStyle(color: Color(0xFF141414)),
    titleLarge: TextStyle(color: Color(0xFF141414)),
    titleMedium: TextStyle(color: Color(0xFF141414)),
    titleSmall: TextStyle(color: Color(0xFF141414)),
    bodyLarge: TextStyle(color: Color(0xFF141414)),
    bodyMedium: TextStyle(color: Color(0xFF5A5A5A)),
    bodySmall: TextStyle(color: Color(0xFF808080)),
    labelLarge: TextStyle(color: Color(0xFF141414), fontWeight: FontWeight.w600),
    labelMedium: TextStyle(color: Color(0xFF5A5A5A)),
    labelSmall: TextStyle(color: Color(0xFF808080)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF5A8F00),
    unselectedLabelColor: Color(0xFF5A5A5A),
    indicatorColor: Color(0xFF5A8F00),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF5A8F00);
      return const Color(0xFF808080);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFA4E04A);
      return const Color(0xFFCCCCCC);
    }),
  ),
);
