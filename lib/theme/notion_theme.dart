// ============================================================
// Notion-inspired Theme
// ============================================================
// Visual Theme: Warm minimalism, serif headings, soft surfaces
// Atmosphere: All-in-one workspace, calm, editorial
// Inspired by: Notion
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #37352F   │ Near-black text, CTA (dark)  │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #EFEEE9   │ Subtle warm bg               │
// │ secondary                │ #9B9A97   │ Muted warm gray — depth      │
// │ tertiary                 │ #2383E2   │ Link blue — sparse accent    │
// │ error                    │ #E03E3E   │ Destructive / danger         │
// │ surface                  │ #FFFFFF   │ Default surface bg           │
// │ onSurface                │ #37352F   │ Primary text                 │
// │ onSurfaceVariant         │ #9B9A97   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #FBFBFA   │ Lowest elevation             │
// │ surfaceContainerLow      │ #F6F5F3   │ Low elevation                │
// │ surfaceContainer         │ #EFEEE9   │ Card / input bg              │
// │ surfaceContainerHigh     │ #E9E8E3   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #E3E2DD   │ Highest elevation (dialogs)  │
// │ outline                  │ #D3D1CB   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Generous padding — breathing room is essential
//   ✓ Use em-dashes and serif touches for headings
//   ✓ Soft, warm neutrals — never pure white or pure black
// Don't:
//   ✗ No harsh shadows — only subtle elevation
//   ✗ Avoid saturated colors — keep it muted and warm
// ============================================================

import 'package:flutter/material.dart';

const Color _notionSeed = Color(0xFF37352F);

// ============================================================
// Notion — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFD4D0C8),
    onPrimary: Color(0xFF191918),
    primaryContainer: Color(0xFF2B2B28),
    onPrimaryContainer: Color(0xFFE8E6E0),
    primaryFixed: Color(0xFFE8E6E0),
    primaryFixedDim: Color(0xFFC8C4BC),
    secondary: Color(0xFF8B8982),
    onSecondary: Color(0xFF191918),
    secondaryContainer: Color(0xFF2B2B28),
    onSecondaryContainer: Color(0xFFD4D0C8),
    secondaryFixed: Color(0xFFD4D0C8),
    secondaryFixedDim: Color(0xFFA8A59E),
    tertiary: Color(0xFF529CE0),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF0A2238),
    onTertiaryContainer: Color(0xFFB3D4FF),
    error: Color(0xFFE03E3E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3E0A0A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF191918),
    onSurface: Color(0xFFE8E6E0),
    onSurfaceVariant: Color(0xFF8B8982),
    surfaceContainerLowest: Color(0xFF121211),
    surfaceContainerLow: Color(0xFF191918),
    surfaceContainer: Color(0xFF20201F),
    surfaceContainerHigh: Color(0xFF282826),
    surfaceContainerHighest: Color(0xFF30302E),
    outline: Color(0xFF3A3A37),
    outlineVariant: Color(0xFF282826),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF191918),
    surfaceBright: Color(0xFF30302E),
    inverseSurface: Color(0xFFE8E6E0),
    inversePrimary: Color(0xFF37352F),
  ),
  scaffoldBackgroundColor: const Color(0xFF191918),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF20201F),
    foregroundColor: Color(0xFFE8E6E0),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD4D0C8),
      foregroundColor: const Color(0xFF191918),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 0,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFD4D0C8),
      foregroundColor: const Color(0xFF191918),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF20201F),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF3A3A37)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF529CE0), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFE03E3E)),
    ),
  ),
  dividerColor: const Color(0xFF3A3A37),
  dividerTheme: const DividerThemeData(color: Color(0xFF3A3A37), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFF20201F),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide.none,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFE8E6E0)),
    displayMedium: TextStyle(color: Color(0xFFE8E6E0)),
    displaySmall: TextStyle(color: Color(0xFFE8E6E0)),
    headlineLarge: TextStyle(color: Color(0xFFE8E6E0)),
    headlineMedium: TextStyle(color: Color(0xFFE8E6E0)),
    headlineSmall: TextStyle(color: Color(0xFFE8E6E0)),
    titleLarge: TextStyle(color: Color(0xFFE8E6E0)),
    titleMedium: TextStyle(color: Color(0xFFE8E6E0)),
    titleSmall: TextStyle(color: Color(0xFFE8E6E0)),
    bodyLarge: TextStyle(color: Color(0xFFE8E6E0)),
    bodyMedium: TextStyle(color: Color(0xFF8B8982)),
    bodySmall: TextStyle(color: Color(0xFF6B6A64)),
    labelLarge: TextStyle(color: Color(0xFFE8E6E0)),
    labelMedium: TextStyle(color: Color(0xFF8B8982)),
    labelSmall: TextStyle(color: Color(0xFF6B6A64)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFD4D0C8),
    unselectedLabelColor: Color(0xFF8B8982),
    indicatorColor: Color(0xFFD4D0C8),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF529CE0);
      return const Color(0xFF8B8982);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF1A3350);
      return const Color(0xFF3A3A37);
    }),
  ),
);

// ============================================================
// Notion — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF37352F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEFEEE9),
    onPrimaryContainer: Color(0xFF121211),
    primaryFixed: Color(0xFFEFEEE9),
    primaryFixedDim: Color(0xFFE3E2DD),
    secondary: Color(0xFF9B9A97),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEFEEE9),
    onSecondaryContainer: Color(0xFF20201F),
    secondaryFixed: Color(0xFFEFEEE9),
    secondaryFixedDim: Color(0xFFD3D1CB),
    tertiary: Color(0xFF2383E2),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD4E8FF),
    onTertiaryContainer: Color(0xFF0A2238),
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF3E0A0A),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF37352F),
    onSurfaceVariant: Color(0xFF9B9A97),
    surfaceContainerLowest: Color(0xFFFBFBFA),
    surfaceContainerLow: Color(0xFFF6F5F3),
    surfaceContainer: Color(0xFFEFEEE9),
    surfaceContainerHigh: Color(0xFFE9E8E3),
    surfaceContainerHighest: Color(0xFFE3E2DD),
    outline: Color(0xFFD3D1CB),
    outlineVariant: Color(0xFFE3E2DD),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFE3E2DD),
    surfaceBright: Color(0xFFFFFFFF),
    inverseSurface: Color(0xFF30302E),
    inversePrimary: Color(0xFFD4D0C8),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFBFBFA),
    foregroundColor: Color(0xFF37352F),
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF37352F),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF6F5F3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFD3D1CB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF2383E2), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),
  dividerColor: const Color(0xFFD3D1CB),
  dividerTheme: const DividerThemeData(color: Color(0xFFD3D1CB), thickness: 1),
  cardTheme: CardThemeData(
    color: const Color(0xFFFBFBFA),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide.none,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF37352F)),
    displayMedium: TextStyle(color: Color(0xFF37352F)),
    displaySmall: TextStyle(color: Color(0xFF37352F)),
    headlineLarge: TextStyle(color: Color(0xFF37352F)),
    headlineMedium: TextStyle(color: Color(0xFF37352F)),
    headlineSmall: TextStyle(color: Color(0xFF37352F)),
    titleLarge: TextStyle(color: Color(0xFF37352F)),
    titleMedium: TextStyle(color: Color(0xFF37352F)),
    titleSmall: TextStyle(color: Color(0xFF37352F)),
    bodyLarge: TextStyle(color: Color(0xFF37352F)),
    bodyMedium: TextStyle(color: Color(0xFF9B9A97)),
    bodySmall: TextStyle(color: Color(0xFFB8B6B0)),
    labelLarge: TextStyle(color: Color(0xFF37352F)),
    labelMedium: TextStyle(color: Color(0xFF9B9A97)),
    labelSmall: TextStyle(color: Color(0xFFB8B6B0)),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF37352F),
    unselectedLabelColor: Color(0xFF9B9A97),
    indicatorColor: Color(0xFF37352F),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF2383E2);
      return const Color(0xFF9B9A97);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFD4E8FF);
      return const Color(0xFFD3D1CB);
    }),
  ),
);
