// ============================================================
// Vercel-inspired Theme
// ============================================================
// Visual Theme: Black and white precision, Geist aesthetic
// Atmosphere: Frontend infrastructure, precision, minimalism
// Inspired by: Vercel
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #000000   │ Brand, CTA, active (dark)    │
// │ onPrimary                │ #FAFAFA   │ Text / icons on primary      │
// │ primaryContainer         │ #E5E5E5   │ Subtle bg                    │
// │ secondary                │ #666666   │ Muted — depth                │
// │ tertiary                 │ #0070F3   │ Link blue — sparse accent    │
// │ error                    │ #EE0000   │ Destructive / danger         │
// │ surface                  │ #FFFFFF   │ Default surface bg           │
// │ onSurface                │ #000000   │ Primary text                 │
// │ onSurfaceVariant         │ #666666   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #F5F5F5   │ Lowest elevation             │
// │ surfaceContainerLow      │ #EDEDED   │ Low elevation                │
// │ surfaceContainer         │ #E5E5E5   │ Card / input bg              │
// │ surfaceContainerHigh     │ #DCDCDC   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #D4D4D4   │ Highest elevation (dialogs)  │
// │ outline                  │ #D4D4D4   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Generous whitespace — let content breathe
//   ✓ Use thin font weights (300) for elegance
//   ✓ Borders are thin (1px) and light (#E5E5E5)
// Don't:
//   ✗ No rounded corners above 6px
//   ✗ No shadows — flat design only
//   ✗ No colored surfaces — only grayscale + single accent
// ============================================================

import 'package:flutter/material.dart';

const Color _vercelSeed = Color(0xFF000000);

// ============================================================
// Vercel — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFAFAFA),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF1A1A1A),
    onPrimaryContainer: Color(0xFFD4D4D4),
    primaryFixed: Color(0xFFD4D4D4),
    primaryFixedDim: Color(0xFFA0A0A0),
    secondary: Color(0xFF888888),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF1A1A1A),
    onSecondaryContainer: Color(0xFFD4D4D4),
    secondaryFixed: Color(0xFFD4D4D4),
    secondaryFixedDim: Color(0xFFA0A0A0),
    tertiary: Color(0xFF0070F3),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF001A3A),
    onTertiaryContainer: Color(0xFFB3D4FF),
    error: Color(0xFFFF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3E0000),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFAFAFA),
    onSurfaceVariant: Color(0xFF888888),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFF111111),
    surfaceContainerHigh: Color(0xFF1A1A1A),
    surfaceContainerHighest: Color(0xFF222222),
    outline: Color(0xFF333333),
    outlineVariant: Color(0xFF222222),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF222222),
    inverseSurface: Color(0xFFD4D4D4),
    inversePrimary: Color(0xFF000000),
  ),
  scaffoldBackgroundColor: const Color(0xFF000000),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF111111),
    foregroundColor: Color(0xFFFAFAFA),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFAFAFA),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFFAFAFA),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF111111),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: Color(0xFF333333)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: Color(0xFFFAFAFA), width: 1),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: Color(0xFFFF4444)),
    ),
  ),
  dividerColor: const Color(0xFF333333),
  dividerTheme: const DividerThemeData(color: Color(0xFF333333), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF111111),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
      side: const BorderSide(color: Color(0xFF333333)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFFAFAFA), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFFFAFAFA), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFFFAFAFA)),
    headlineLarge: TextStyle(color: Color(0xFFFAFAFA), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFFFAFAFA)),
    headlineSmall: TextStyle(color: Color(0xFFFAFAFA)),
    titleLarge: TextStyle(color: Color(0xFFFAFAFA)),
    titleMedium: TextStyle(color: Color(0xFFFAFAFA)),
    titleSmall: TextStyle(color: Color(0xFFFAFAFA)),
    bodyLarge: TextStyle(color: Color(0xFFFAFAFA)),
    bodyMedium: TextStyle(color: Color(0xFF888888)),
    bodySmall: TextStyle(color: Color(0xFF666666)),
    labelLarge: TextStyle(color: Color(0xFFFAFAFA)),
    labelMedium: TextStyle(color: Color(0xFF888888)),
    labelSmall: TextStyle(color: Color(0xFF666666)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFFAFAFA),
    unselectedLabelColor: Color(0xFF888888),
    indicatorColor: Color(0xFFFAFAFA),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFAFAFA);
      return const Color(0xFF888888);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF333333);
      return const Color(0xFF222222);
    }),
  ),
);

// ============================================================
// Vercel — Light Theme
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
    secondary: Color(0xFF666666),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDEDED),
    onSecondaryContainer: Color(0xFF1A1A1A),
    secondaryFixed: Color(0xFFEDEDED),
    secondaryFixedDim: Color(0xFFDCDCDC),
    tertiary: Color(0xFF0070F3),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB3D4FF),
    onTertiaryContainer: Color(0xFF001A3A),
    error: Color(0xFFEE0000),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF3E0000),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    onSurfaceVariant: Color(0xFF666666),
    surfaceContainerLowest: Color(0xFFF5F5F5),
    surfaceContainerLow: Color(0xFFEDEDED),
    surfaceContainer: Color(0xFFE5E5E5),
    surfaceContainerHigh: Color(0xFFDCDCDC),
    surfaceContainerHighest: Color(0xFFD4D4D4),
    outline: Color(0xFFD4D4D4),
    outlineVariant: Color(0xFFE5E5E5),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFD4D4D4),
    surfaceBright: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF1A1A1A),
    inversePrimary: Color(0xFFD4D4D4),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F5),
    foregroundColor: Color(0xFF000000),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF000000),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: Color(0xFFD4D4D4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: Color(0xFF000000), width: 1),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      borderSide: BorderSide(color: Color(0xFFEE0000)),
    ),
  ),
  dividerColor: const Color(0xFFD4D4D4),
  dividerTheme: const DividerThemeData(color: Color(0xFFD4D4D4), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFF5F5F5),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
      side: const BorderSide(color: Color(0xFFD4D4D4)),
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
    bodyMedium: TextStyle(color: Color(0xFF666666)),
    bodySmall: TextStyle(color: Color(0xFF888888)),
    labelLarge: TextStyle(color: Color(0xFF000000)),
    labelMedium: TextStyle(color: Color(0xFF666666)),
    labelSmall: TextStyle(color: Color(0xFF888888)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF000000),
    unselectedLabelColor: Color(0xFF666666),
    indicatorColor: Color(0xFF000000),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF000000);
      return const Color(0xFF666666);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFD4D4D4);
      return const Color(0xFFE5E5E5);
    }),
  ),
);
