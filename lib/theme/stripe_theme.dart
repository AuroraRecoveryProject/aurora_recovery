// ============================================================
// Stripe-inspired Theme
// ============================================================
// Visual Theme: Signature purple gradients, weight-300 elegance
// Atmosphere: Payment infrastructure, trust, precision
// Inspired by: Stripe
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #635BFF   │ Brand purple, CTA, active    │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #1C185E   │ Subtle purple bg             │
// │ secondary                │ #7A73FF   │ Lighter purple — depth       │
// │ tertiary                 │ #00D4FF   │ Cyan accent — sparse glow    │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ surface                  │ #0F0D16   │ Default surface bg           │
// │ onSurface                │ #E8E6F0   │ Primary text                 │
// │ onSurfaceVariant         │ #8A87A0   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #080710   │ Deepest void                 │
// │ surfaceContainerLow      │ #0F0D16   │ Low elevation                │
// │ surfaceContainer         │ #15131F   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1D1A2A   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #252235   │ Highest elevation (dialogs)  │
// │ outline                  │ #2E2A3E   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Use light font weights (300) for display text — elegant
//   ✓ Purple gradients for CTAs and brand moments
//   ✓ Smooth, rounded surfaces — 12px radius minimum
// Don't:
//   ✗ Don't overuse purple — let the dark surfaces dominate
//   ✗ Never use sharp corners — everything is smooth
// ============================================================

import 'package:flutter/material.dart';

const Color _stripeSeed = Color(0xFF635BFF);

// ============================================================
// Stripe — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF635BFF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF1C185E),
    onPrimaryContainer: Color(0xFFCFC8FF),
    primaryFixed: Color(0xFFCFC8FF),
    primaryFixedDim: Color(0xFF9A90FF),
    secondary: Color(0xFF7A73FF),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF201A5A),
    onSecondaryContainer: Color(0xFFCFC8FF),
    secondaryFixed: Color(0xFFCFC8FF),
    secondaryFixedDim: Color(0xFF9A90FF),
    tertiary: Color(0xFF00D4FF),
    onTertiary: Color(0xFF001A20),
    tertiaryContainer: Color(0xFF003545),
    onTertiaryContainer: Color(0xFFB3F0FF),
    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),
    surface: Color(0xFF0F0D16),
    onSurface: Color(0xFFE8E6F0),
    onSurfaceVariant: Color(0xFF8A87A0),
    surfaceContainerLowest: Color(0xFF080710),
    surfaceContainerLow: Color(0xFF0F0D16),
    surfaceContainer: Color(0xFF15131F),
    surfaceContainerHigh: Color(0xFF1D1A2A),
    surfaceContainerHighest: Color(0xFF252235),
    outline: Color(0xFF2E2A3E),
    outlineVariant: Color(0xFF1D1A2A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0F0D16),
    surfaceBright: Color(0xFF252235),
    inverseSurface: Color(0xFFE8E6F0),
    inversePrimary: Color(0xFF4238CC),
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0D16),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF15131F),
    foregroundColor: Color(0xFFE8E6F0),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF635BFF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF635BFF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF15131F),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF2E2A3E)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF635BFF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),
  dividerColor: const Color(0xFF2E2A3E),
  dividerTheme: const DividerThemeData(color: Color(0xFF2E2A3E), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF15131F),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF2E2A3E)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFE8E6F0), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFFE8E6F0), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFFE8E6F0)),
    headlineLarge: TextStyle(color: Color(0xFFE8E6F0), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFFE8E6F0)),
    headlineSmall: TextStyle(color: Color(0xFFE8E6F0)),
    titleLarge: TextStyle(color: Color(0xFFE8E6F0)),
    titleMedium: TextStyle(color: Color(0xFFE8E6F0)),
    titleSmall: TextStyle(color: Color(0xFFE8E6F0)),
    bodyLarge: TextStyle(color: Color(0xFFE8E6F0)),
    bodyMedium: TextStyle(color: Color(0xFF8A87A0)),
    bodySmall: TextStyle(color: Color(0xFF6B6880)),
    labelLarge: TextStyle(color: Color(0xFFE8E6F0)),
    labelMedium: TextStyle(color: Color(0xFF8A87A0)),
    labelSmall: TextStyle(color: Color(0xFF6B6880)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF635BFF),
    unselectedLabelColor: Color(0xFF8A87A0),
    indicatorColor: Color(0xFF635BFF),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF635BFF);
      return const Color(0xFF8A87A0);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF2E2850);
      return const Color(0xFF2E2A3E);
    }),
  ),
);

// ============================================================
// Stripe — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF4238CC),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8E5FF),
    onPrimaryContainer: Color(0xFF0F0C40),
    primaryFixed: Color(0xFFE8E5FF),
    primaryFixedDim: Color(0xFFC8C0FF),
    secondary: Color(0xFF5C55D6),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0DDFF),
    onSecondaryContainer: Color(0xFF120D3A),
    secondaryFixed: Color(0xFFE0DDFF),
    secondaryFixedDim: Color(0xFFC8C0FF),
    tertiary: Color(0xFF007A99),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB3F0FF),
    onTertiaryContainer: Color(0xFF001A20),
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),
    surface: Color(0xFFF8F7FF),
    onSurface: Color(0xFF15131F),
    onSurfaceVariant: Color(0xFF5E5B72),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2F0FA),
    surfaceContainer: Color(0xFFEBE8F5),
    surfaceContainerHigh: Color(0xFFE5E2F0),
    surfaceContainerHighest: Color(0xFFDFDCEB),
    outline: Color(0xFFCAC6D6),
    outlineVariant: Color(0xFFDFDCEB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDFDCEB),
    surfaceBright: Color(0xFFF8F7FF),
    inverseSurface: Color(0xFF252235),
    inversePrimary: Color(0xFF9A90FF),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F7FF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEBE8F5),
    foregroundColor: Color(0xFF15131F),
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4238CC),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFEBE8F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFCAC6D6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF4238CC), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),
  dividerColor: const Color(0xFFCAC6D6),
  dividerTheme: const DividerThemeData(color: Color(0xFFCAC6D6), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFEBE8F5),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFCAC6D6)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF15131F), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFF15131F), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFF15131F)),
    headlineLarge: TextStyle(color: Color(0xFF15131F), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFF15131F)),
    headlineSmall: TextStyle(color: Color(0xFF15131F)),
    titleLarge: TextStyle(color: Color(0xFF15131F)),
    titleMedium: TextStyle(color: Color(0xFF15131F)),
    titleSmall: TextStyle(color: Color(0xFF15131F)),
    bodyLarge: TextStyle(color: Color(0xFF15131F)),
    bodyMedium: TextStyle(color: Color(0xFF5E5B72)),
    bodySmall: TextStyle(color: Color(0xFF7D7A90)),
    labelLarge: TextStyle(color: Color(0xFF15131F)),
    labelMedium: TextStyle(color: Color(0xFF5E5B72)),
    labelSmall: TextStyle(color: Color(0xFF7D7A90)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF4238CC),
    unselectedLabelColor: Color(0xFF5E5B72),
    indicatorColor: Color(0xFF4238CC),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF4238CC);
      return const Color(0xFF8A87A0);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFC8C0FF);
      return const Color(0xFFCAC6D6);
    }),
  ),
);
