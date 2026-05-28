// ============================================================
// Sentry-inspired Theme
// ============================================================
// Visual Theme: Dark dashboard, data-dense, pink-purple accent
// Atmosphere: Error monitoring, developer tools, alert-driven
// Inspired by: Sentry
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #F02E7E   │ Brand pink, CTA, alert       │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #3D0F28   │ Subtle pink bg               │
// │ secondary                │ #8C4BC5   │ Purple depth accent          │
// │ tertiary                 │ #FF6B9D   │ Bright pink — sparse glow    │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ surface                  │ #1A0E1E   │ Default surface bg           │
// │ onSurface                │ #EDE1F0   │ Primary text                 │
// │ onSurfaceVariant         │ #9B8A9E   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #12071A   │ Deepest void                 │
// │ surfaceContainerLow      │ #1A0E1E   │ Low elevation                │
// │ surfaceContainer         │ #221428   │ Card / input bg              │
// │ surfaceContainerHigh     │ #2A1A32   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #33223C   │ Highest elevation (dialogs)  │
// │ outline                  │ #3D2E46   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Use pink for alerts, errors, and primary CTAs
//   ✓ Data-dense layouts are welcome — this is a monitoring tool
//   ✓ Purple secondary for depth and category distinction
// Don't:
//   ✗ Don't use pink for non-critical UI — reserve it for attention
//   ✗ Avoid pure black — use the deep purple-black instead
// ============================================================

import 'package:flutter/material.dart';

const Color _sentrySeed = Color(0xFFF02E7E);

// ============================================================
// Sentry — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Robot',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFF02E7E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3D0F28),
    onPrimaryContainer: Color(0xFFFFD9E8),
    primaryFixed: Color(0xFFFFD9E8),
    primaryFixedDim: Color(0xFFFF6B9D),

    secondary: Color(0xFF8C4BC5),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF2E1040),
    onSecondaryContainer: Color(0xFFEBD6FF),
    secondaryFixed: Color(0xFFEBD6FF),
    secondaryFixedDim: Color(0xFFC084FC),

    tertiary: Color(0xFFFF6B9D),
    onTertiary: Color(0xFF3D0F28),
    tertiaryContainer: Color(0xFF5C1A3A),
    onTertiaryContainer: Color(0xFFFFD9E8),

    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),

    surface: Color(0xFF1A0E1E),
    onSurface: Color(0xFFEDE1F0),
    onSurfaceVariant: Color(0xFF9B8A9E),
    surfaceContainerLowest: Color(0xFF12071A),
    surfaceContainerLow: Color(0xFF1A0E1E),
    surfaceContainer: Color(0xFF221428),
    surfaceContainerHigh: Color(0xFF2A1A32),
    surfaceContainerHighest: Color(0xFF33223C),

    outline: Color(0xFF3D2E46),
    outlineVariant: Color(0xFF2A1A32),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF1A0E1E),
    surfaceBright: Color(0xFF33223C),
    inverseSurface: Color(0xFFEDE1F0),
    inversePrimary: Color(0xFFC01E62),
  ),
  scaffoldBackgroundColor: const Color(0xFF1A0E1E),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF221428),
    foregroundColor: Color(0xFFEDE1F0),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF02E7E),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFF02E7E),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF221428),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFF3D2E46)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFF02E7E), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),

  dividerColor: const Color(0xFF3D2E46),
  dividerTheme: const DividerThemeData(color: Color(0xFF3D2E46), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFF221428),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xFF3D2E46)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFEDE1F0)),
    displayMedium: TextStyle(color: Color(0xFFEDE1F0)),
    displaySmall: TextStyle(color: Color(0xFFEDE1F0)),
    headlineLarge: TextStyle(color: Color(0xFFEDE1F0)),
    headlineMedium: TextStyle(color: Color(0xFFEDE1F0)),
    headlineSmall: TextStyle(color: Color(0xFFEDE1F0)),
    titleLarge: TextStyle(color: Color(0xFFEDE1F0)),
    titleMedium: TextStyle(color: Color(0xFFEDE1F0)),
    titleSmall: TextStyle(color: Color(0xFFEDE1F0)),
    bodyLarge: TextStyle(color: Color(0xFFEDE1F0)),
    bodyMedium: TextStyle(color: Color(0xFF9B8A9E)),
    bodySmall: TextStyle(color: Color(0xFF6E5E72)),
    labelLarge: TextStyle(color: Color(0xFFEDE1F0)),
    labelMedium: TextStyle(color: Color(0xFF9B8A9E)),
    labelSmall: TextStyle(color: Color(0xFF6E5E72)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFF02E7E),
    unselectedLabelColor: Color(0xFF9B8A9E),
    indicatorColor: Color(0xFFF02E7E),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFF02E7E);
      return const Color(0xFF9B8A9E);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF5C1A3A);
      return const Color(0xFF3D2E46);
    }),
  ),
);

// ============================================================
// Sentry — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFC01E62),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFD9E8),
    onPrimaryContainer: Color(0xFF3D0F28),
    primaryFixed: Color(0xFFFFD9E8),
    primaryFixedDim: Color(0xFFFF6B9D),

    secondary: Color(0xFF6B21C4),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEBD6FF),
    onSecondaryContainer: Color(0xFF2E1040),
    secondaryFixed: Color(0xFFEBD6FF),
    secondaryFixedDim: Color(0xFFC084FC),

    tertiary: Color(0xFFD91A6E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD9E8),
    onTertiaryContainer: Color(0xFF3D0F28),

    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),

    surface: Color(0xFFFAF5FB),
    onSurface: Color(0xFF221428),
    onSurfaceVariant: Color(0xFF5C4E62),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5EDF8),
    surfaceContainer: Color(0xFFEDE1F0),
    surfaceContainerHigh: Color(0xFFE5D9EB),
    surfaceContainerHighest: Color(0xFFDDD0E5),

    outline: Color(0xFFC8B8D0),
    outlineVariant: Color(0xFFDDD0E5),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDDD0E5),
    surfaceBright: Color(0xFFFAF5FB),
    inverseSurface: Color(0xFF33223C),
    inversePrimary: Color(0xFFFF6B9D),
  ),
  scaffoldBackgroundColor: const Color(0xFFFAF5FB),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEDE1F0),
    foregroundColor: Color(0xFF221428),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFC01E62),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFEDE1F0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFC8B8D0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFC01E62), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),

  dividerColor: const Color(0xFFC8B8D0),
  dividerTheme: const DividerThemeData(color: Color(0xFFC8B8D0), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFFEDE1F0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xFFC8B8D0)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF221428)),
    displayMedium: TextStyle(color: Color(0xFF221428)),
    displaySmall: TextStyle(color: Color(0xFF221428)),
    headlineLarge: TextStyle(color: Color(0xFF221428)),
    headlineMedium: TextStyle(color: Color(0xFF221428)),
    headlineSmall: TextStyle(color: Color(0xFF221428)),
    titleLarge: TextStyle(color: Color(0xFF221428)),
    titleMedium: TextStyle(color: Color(0xFF221428)),
    titleSmall: TextStyle(color: Color(0xFF221428)),
    bodyLarge: TextStyle(color: Color(0xFF221428)),
    bodyMedium: TextStyle(color: Color(0xFF5C4E62)),
    bodySmall: TextStyle(color: Color(0xFF7A6B80)),
    labelLarge: TextStyle(color: Color(0xFF221428)),
    labelMedium: TextStyle(color: Color(0xFF5C4E62)),
    labelSmall: TextStyle(color: Color(0xFF7A6B80)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFC01E62),
    unselectedLabelColor: Color(0xFF5C4E62),
    indicatorColor: Color(0xFFC01E62),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFC01E62);
      return const Color(0xFF9B8A9E);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFF6B9D);
      return const Color(0xFFC8B8D0);
    }),
  ),
);
