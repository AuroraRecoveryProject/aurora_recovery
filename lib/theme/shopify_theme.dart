// ============================================================
// Shopify-inspired Theme
// ============================================================
// Visual Theme: Dark-first cinematic, neon green accent, ultra-light display
// Atmosphere: E-commerce platform, enterprise, bold
// Inspired by: Shopify
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #95BF47   │ Shopify Green, CTA, active   │
// │ onPrimary                │ #000000   │ Text / icons on primary      │
// │ primaryContainer         │ #1A2E00   │ Subtle green bg              │
// │ secondary                │ #3D5A1E   │ Forest green — depth         │
// │ tertiary                 │ #C5FF5A   │ Neon green — sparse glow     │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ surface                  │ #000000   │ Default surface bg           │
// │ onSurface                │ #F1F1EC   │ Primary text                 │
// │ onSurfaceVariant         │ #86867E   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #030303   │ Deepest black                │
// │ surfaceContainerLow      │ #080808   │ Low elevation                │
// │ surfaceContainer         │ #0F0F0F   │ Card / input bg              │
// │ surfaceContainerHigh     │ #171717   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #202020   │ Highest elevation (dialogs)  │
// │ outline                  │ #2A2A2A   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Ultra-light display type for headings (weight 300)
//   ✓ Dark-first cinematic feel — black is the brand
//   ✓ Neon green reserved for CTAs — bold and punchy
// Don't:
//   ✗ Never use green as decoration — it means action
//   ✗ Avoid white backgrounds — this is dark-first
// ============================================================

import 'package:flutter/material.dart';

const Color _shopifySeed = Color(0xFF95BF47);

// ============================================================
// Shopify — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF95BF47),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF1A2E00),
    onPrimaryContainer: Color(0xFFD4FF80),
    primaryFixed: Color(0xFFD4FF80),
    primaryFixedDim: Color(0xFFC5FF5A),
    secondary: Color(0xFF3D5A1E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF202010),
    onSecondaryContainer: Color(0xFFC0D0A0),
    secondaryFixed: Color(0xFFC0D0A0),
    secondaryFixedDim: Color(0xFF95BF47),
    tertiary: Color(0xFFC5FF5A),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF2E4A00),
    onTertiaryContainer: Color(0xFFD4FF80),
    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFF1F1EC),
    onSurfaceVariant: Color(0xFF86867E),
    surfaceContainerLowest: Color(0xFF030303),
    surfaceContainerLow: Color(0xFF080808),
    surfaceContainer: Color(0xFF0F0F0F),
    surfaceContainerHigh: Color(0xFF171717),
    surfaceContainerHighest: Color(0xFF202020),
    outline: Color(0xFF2A2A2A),
    outlineVariant: Color(0xFF171717),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF202020),
    inverseSurface: Color(0xFFF1F1EC),
    inversePrimary: Color(0xFF6A8F33),
  ),
  scaffoldBackgroundColor: const Color(0xFF000000),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F0F0F),
    foregroundColor: Color(0xFFF1F1EC),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF95BF47),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF95BF47),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF0F0F0F),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFF2A2A2A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFF95BF47), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),
  dividerColor: const Color(0xFF2A2A2A),
  dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF0F0F0F),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: Color(0xFF2A2A2A)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFF1F1EC), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFFF1F1EC), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFFF1F1EC), fontWeight: FontWeight.w300),
    headlineLarge: TextStyle(color: Color(0xFFF1F1EC), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFFF1F1EC)),
    headlineSmall: TextStyle(color: Color(0xFFF1F1EC)),
    titleLarge: TextStyle(color: Color(0xFFF1F1EC)),
    titleMedium: TextStyle(color: Color(0xFFF1F1EC)),
    titleSmall: TextStyle(color: Color(0xFFF1F1EC)),
    bodyLarge: TextStyle(color: Color(0xFFF1F1EC)),
    bodyMedium: TextStyle(color: Color(0xFF86867E)),
    bodySmall: TextStyle(color: Color(0xFF5E5E58)),
    labelLarge: TextStyle(color: Color(0xFFF1F1EC)),
    labelMedium: TextStyle(color: Color(0xFF86867E)),
    labelSmall: TextStyle(color: Color(0xFF5E5E58)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF95BF47),
    unselectedLabelColor: Color(0xFF86867E),
    indicatorColor: Color(0xFF95BF47),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF95BF47);
      return const Color(0xFF86867E);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF2E4A00);
      return const Color(0xFF2A2A2A);
    }),
  ),
);

// ============================================================
// Shopify — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF6A8F33),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4FF80),
    onPrimaryContainer: Color(0xFF1A2E00),
    primaryFixed: Color(0xFFD4FF80),
    primaryFixedDim: Color(0xFFC5FF5A),
    secondary: Color(0xFF3D5A1E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFC0D0A0),
    onSecondaryContainer: Color(0xFF121800),
    secondaryFixed: Color(0xFFC0D0A0),
    secondaryFixedDim: Color(0xFF95BF47),
    tertiary: Color(0xFF6A8F33),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD4FF80),
    onTertiaryContainer: Color(0xFF1A2E00),
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),
    surface: Color(0xFFFBFBF7),
    onSurface: Color(0xFF0F0F0F),
    onSurfaceVariant: Color(0xFF5E5E58),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F5F0),
    surfaceContainer: Color(0xFFEEEEE9),
    surfaceContainerHigh: Color(0xFFE8E8E3),
    surfaceContainerHighest: Color(0xFFE2E2DD),
    outline: Color(0xFFD0D0CA),
    outlineVariant: Color(0xFFE2E2DD),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFE2E2DD),
    surfaceBright: Color(0xFFFBFBF7),
    inverseSurface: Color(0xFF202020),
    inversePrimary: Color(0xFFC5FF5A),
  ),
  scaffoldBackgroundColor: const Color(0xFFFBFBF7),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEEEEE9),
    foregroundColor: Color(0xFF0F0F0F),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6A8F33),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFEEEEE9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFFD0D0CA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFF6A8F33), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),
  dividerColor: const Color(0xFFD0D0CA),
  dividerTheme: const DividerThemeData(color: Color(0xFFD0D0CA), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFEEEEE9),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: Color(0xFFD0D0CA)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF0F0F0F), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFF0F0F0F), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFF0F0F0F), fontWeight: FontWeight.w300),
    headlineLarge: TextStyle(color: Color(0xFF0F0F0F), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFF0F0F0F)),
    headlineSmall: TextStyle(color: Color(0xFF0F0F0F)),
    titleLarge: TextStyle(color: Color(0xFF0F0F0F)),
    titleMedium: TextStyle(color: Color(0xFF0F0F0F)),
    titleSmall: TextStyle(color: Color(0xFF0F0F0F)),
    bodyLarge: TextStyle(color: Color(0xFF0F0F0F)),
    bodyMedium: TextStyle(color: Color(0xFF5E5E58)),
    bodySmall: TextStyle(color: Color(0xFF7A7A74)),
    labelLarge: TextStyle(color: Color(0xFF0F0F0F)),
    labelMedium: TextStyle(color: Color(0xFF5E5E58)),
    labelSmall: TextStyle(color: Color(0xFF7A7A74)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF6A8F33),
    unselectedLabelColor: Color(0xFF5E5E58),
    indicatorColor: Color(0xFF6A8F33),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF6A8F33);
      return const Color(0xFF86867E);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFC5FF5A);
      return const Color(0xFFD0D0CA);
    }),
  ),
);
