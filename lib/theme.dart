// ============================================================
// Aurora Recovery — Design System
// ============================================================
// Visual Theme: Deep space void with auroral cyan & teal
// Atmosphere: Technical, terminal-native, northern-lights glow
// Inspired by: Warp + Supabase + Shopify Dark
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #06B6D4   │ Brand, CTA, active, focus    │
// │ onPrimary                │ #003540   │ Text / icons on primary      │
// │ primaryContainer         │ #004D5C   │ Subtle primary bg (badges)   │
// │ onPrimaryContainer       │ #B3F0FF   │ Text on primaryContainer     │
// │ secondary                │ #0D9488   │ Aurora teal — depth accent   │
// │ onSecondary              │ #002A26   │ Text / icons on secondary    │
// │ secondaryContainer       │ #003731   │ Subtle secondary bg          │
// │ tertiary                 │ #22D3EE   │ Aurora bright — sparse glow  │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ onError                  │ #FFFFFF   │ Text / icons on error        │
// │ surface                  │ #0B0B0E   │ Default surface bg           │
// │ onSurface                │ #EDEDF0   │ Primary text                 │
// │ onSurfaceVariant         │ #9CA3AF   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #07070A   │ Deepest void                 │
// │ surfaceContainerLow      │ #101014   │ Low elevation                │
// │ surfaceContainer         │ #17171C   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1F1F25   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #282830   │ Highest elevation (dialogs)  │
// │ outline                  │ #3F3F46   │ Borders, dividers            │
// │ outlineVariant           │ #282830   │ Subtle borders               │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Surface Hierarchy (Dark):
//   lowest  → #07070A  deepest void
//   low     → #101014  slight lift (+9)
//   default → #17171C  cards, inputs (+7)
//   high    → #1F1F25  sidebar, drawer (+8)
//   highest → #282830  dialogs, popups (+9)
//
// Do:
//   ✓ Use surfaceContainer* for elevation hierarchy
//   ✓ Use onSurface / onSurfaceVariant for text levels
//   ✓ Use tertiary (#22D3EE) only for sparse glow highlights
// Don't:
//   ✗ Don't hardcode hex colors in pages — use colorScheme
//   ✗ Don't tint surfaces with primary hue (hurts contrast)
//   ✗ Don't overuse cyan — let the dark space breathe
// ============================================================

import 'package:flutter/material.dart';

// --- Brand seed ---
const Color seedColor = Color(0xFF06B6D4);

// ============================================================
// Aurora Cyan — Dark Theme
// ============================================================
final ThemeData auroraDark = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    // --- Brand: Aurora Cyan ---
    primary: Color(0xFF06B6D4),
    onPrimary: Color(0xFF003540),
    primaryContainer: Color(0xFF004D5C),
    onPrimaryContainer: Color(0xFFB3F0FF),
    primaryFixed: Color(0xFFB3F0FF),
    primaryFixedDim: Color(0xFF22D3EE),

    // --- Aurora Teal (depth) ---
    secondary: Color(0xFF0D9488),
    onSecondary: Color(0xFF002A26),
    secondaryContainer: Color(0xFF003731),
    onSecondaryContainer: Color(0xFFA7F3D0),
    secondaryFixed: Color(0xFFA7F3D0),
    secondaryFixedDim: Color(0xFF5EEAD4),

    // --- Aurora Bright (sparse glow) ---
    tertiary: Color(0xFF22D3EE),
    onTertiary: Color(0xFF003540),
    tertiaryContainer: Color(0xFF155E75),
    onTertiaryContainer: Color(0xFFCFFAFE),

    // --- Semantic: Error ---
    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),

    // --- Surface Hierarchy ---
    surface: Color(0xFF0B0B0E),
    onSurface: Color(0xFFEDEDF0),
    onSurfaceVariant: Color(0xFF9CA3AF),
    surfaceContainerLowest: Color(0xFF07070A),
    surfaceContainerLow: Color(0xFF101014),
    surfaceContainer: Color(0xFF17171C),
    surfaceContainerHigh: Color(0xFF1F1F25),
    surfaceContainerHighest: Color(0xFF282830),

    // --- Utility ---
    outline: Color(0xFF3F3F46),
    outlineVariant: Color(0xFF282830),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0B0B0E),
    surfaceBright: Color(0xFF282830),
    inverseSurface: Color(0xFFE4E4E7),
    inversePrimary: Color(0xFF0891B2),
  ),
  scaffoldBackgroundColor: const Color(0xFF0B0B0E),

  // --- AppBar ---
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF17171C),
    foregroundColor: Color(0xFFEDEDF0),
    elevation: 0,
    centerTitle: true,
  ),

  // --- Buttons ---
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF06B6D4),
      foregroundColor: const Color(0xFF003540),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF06B6D4),
      foregroundColor: const Color(0xFF003540),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // --- Inputs ---
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF17171C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF3F3F46)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF06B6D4), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),

  // --- Dividers ---
  dividerColor: const Color(0xFF3F3F46),
  dividerTheme: const DividerThemeData(
    color: Color(0xFF3F3F46),
    thickness: 1,
  ),

  // --- Cards ---
  cardTheme: CardThemeData(
    color: const Color(0xFF17171C),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF3F3F46)),
    ),
  ),

  // --- Text ---
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFEDEDF0)),
    displayMedium: TextStyle(color: Color(0xFFEDEDF0)),
    displaySmall: TextStyle(color: Color(0xFFEDEDF0)),
    headlineLarge: TextStyle(color: Color(0xFFEDEDF0)),
    headlineMedium: TextStyle(color: Color(0xFFEDEDF0)),
    headlineSmall: TextStyle(color: Color(0xFFEDEDF0)),
    titleLarge: TextStyle(color: Color(0xFFEDEDF0)),
    titleMedium: TextStyle(color: Color(0xFFEDEDF0)),
    titleSmall: TextStyle(color: Color(0xFFEDEDF0)),
    bodyLarge: TextStyle(color: Color(0xFFEDEDF0)),
    bodyMedium: TextStyle(color: Color(0xFF9CA3AF)),
    bodySmall: TextStyle(color: Color(0xFF6B7280)),
    labelLarge: TextStyle(color: Color(0xFFEDEDF0)),
    labelMedium: TextStyle(color: Color(0xFF9CA3AF)),
    labelSmall: TextStyle(color: Color(0xFF6B7280)),
  ),

  // --- Tab Bar ---
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF06B6D4),
    unselectedLabelColor: Color(0xFF9CA3AF),
    indicatorColor: Color(0xFF06B6D4),
  ),

  // --- Switch ---
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF06B6D4);
      return const Color(0xFF9CA3AF);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF155E75);
      return const Color(0xFF3F3F46);
    }),
  ),
);

// ============================================================
// Aurora Cyan — Light Theme
// ============================================================
final ThemeData auroraLight = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    // --- Brand: Aurora Cyan (darker for light bg contrast) ---
    primary: Color(0xFF0E7490),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCFFAFE),
    onPrimaryContainer: Color(0xFF003540),
    primaryFixed: Color(0xFFCFFAFE),
    primaryFixedDim: Color(0xFF67E8F9),

    // --- Aurora Teal ---
    secondary: Color(0xFF0F766E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCCFBF1),
    onSecondaryContainer: Color(0xFF002A26),
    secondaryFixed: Color(0xFFCCFBF1),
    secondaryFixedDim: Color(0xFF99F6E4),

    // --- Aurora Bright ---
    tertiary: Color(0xFF0891B2),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCFFAFE),
    onTertiaryContainer: Color(0xFF003540),

    // --- Semantic: Error ---
    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),

    // --- Surface Hierarchy ---
    surface: Color(0xFFF8F9FA),
    onSurface: Color(0xFF17171C),
    onSurfaceVariant: Color(0xFF4B5563),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF1F5F9),
    surfaceContainer: Color(0xFFE8EDF2),
    surfaceContainerHigh: Color(0xFFE0E5EB),
    surfaceContainerHighest: Color(0xFFD8DEE4),

    // --- Utility ---
    outline: Color(0xFFCDD5DC),
    outlineVariant: Color(0xFFD8DEE4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFD8DEE4),
    surfaceBright: Color(0xFFF8F9FA),
    inverseSurface: Color(0xFF282830),
    inversePrimary: Color(0xFF67E8F9),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),

  // --- AppBar ---
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFE8EDF2),
    foregroundColor: Color(0xFF17171C),
    elevation: 0,
    centerTitle: true,
  ),

  // --- Buttons ---
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0E7490),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // --- Inputs ---
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFE8EDF2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFCDD5DC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF0E7490), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),

  // --- Dividers ---
  dividerColor: const Color(0xFFCDD5DC),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFCDD5DC),
    thickness: 1,
  ),

  // --- Cards ---
  cardTheme: CardThemeData(
    color: const Color(0xFFE8EDF2),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFCDD5DC)),
    ),
  ),

  // --- Text ---
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF17171C)),
    displayMedium: TextStyle(color: Color(0xFF17171C)),
    displaySmall: TextStyle(color: Color(0xFF17171C)),
    headlineLarge: TextStyle(color: Color(0xFF17171C)),
    headlineMedium: TextStyle(color: Color(0xFF17171C)),
    headlineSmall: TextStyle(color: Color(0xFF17171C)),
    titleLarge: TextStyle(color: Color(0xFF17171C)),
    titleMedium: TextStyle(color: Color(0xFF17171C)),
    titleSmall: TextStyle(color: Color(0xFF17171C)),
    bodyLarge: TextStyle(color: Color(0xFF17171C)),
    bodyMedium: TextStyle(color: Color(0xFF4B5563)),
    bodySmall: TextStyle(color: Color(0xFF6B7280)),
    labelLarge: TextStyle(color: Color(0xFF17171C)),
    labelMedium: TextStyle(color: Color(0xFF4B5563)),
    labelSmall: TextStyle(color: Color(0xFF6B7280)),
  ),

  // --- Tab Bar ---
  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF0E7490),
    unselectedLabelColor: Color(0xFF4B5563),
    indicatorColor: Color(0xFF0E7490),
  ),

  // --- Switch ---
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF0E7490);
      return const Color(0xFF9CA3AF);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF67E8F9);
      return const Color(0xFFCDD5DC);
    }),
  ),
);

// ============================================================
// Legacy aliases
// ============================================================
final ThemeData darkTheme = auroraDark;
final ThemeData lightTheme = auroraLight;

final ThemeData pinkLight = auroraLight;
final ThemeData pinkDark = auroraDark;
