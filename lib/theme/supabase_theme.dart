// ============================================================
// Supabase-inspired Theme
// ============================================================
// Visual Theme: Dark emerald, code-first, developer infrastructure
// Atmosphere: Open-source, trust-worthy, database-console
// Inspired by: Supabase
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #3ECF8E   │ Brand, CTA, active, focus    │
// │ onPrimary                │ #003320   │ Text / icons on primary      │
// │ primaryContainer         │ #004D2E   │ Subtle primary bg            │
// │ secondary                │ #1F8A70   │ Deeper emerald — depth       │
// │ tertiary                 │ #6EE7B7   │ Bright mint — sparse glow    │
// │ error                    │ #F43F5E   │ Destructive / danger         │
// │ surface                  │ #0D0D0D   │ Default surface bg           │
// │ onSurface                │ #E4E4E7   │ Primary text                 │
// │ onSurfaceVariant         │ #71717A   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #080808   │ Deepest void                 │
// │ surfaceContainerLow      │ #111111   │ Low elevation                │
// │ surfaceContainer         │ #18181B   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1F1F23   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #27272D   │ Highest elevation (dialogs)  │
// │ outline                  │ #27272D   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Use monospace for code blocks and data display
//   ✓ Let the emerald accent signal success/active states
//   ✓ Keep layout code-first — dense but readable
// Don't:
//   ✗ Don't over-use green — it's for actionable elements only
//   ✗ No decorative elements, every pixel should serve function
// ============================================================

import 'package:flutter/material.dart';

const Color _supabaseSeed = Color(0xFF3ECF8E);

// ============================================================
// Supabase — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Robot',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3ECF8E),
    onPrimary: Color(0xFF003320),
    primaryContainer: Color(0xFF004D2E),
    onPrimaryContainer: Color(0xFFA7F3D0),
    primaryFixed: Color(0xFFA7F3D0),
    primaryFixedDim: Color(0xFF6EE7B7),

    secondary: Color(0xFF1F8A70),
    onSecondary: Color(0xFF001A10),
    secondaryContainer: Color(0xFF003825),
    onSecondaryContainer: Color(0xFF99F6E0),
    secondaryFixed: Color(0xFF99F6E0),
    secondaryFixedDim: Color(0xFF5EEAD4),

    tertiary: Color(0xFF6EE7B7),
    onTertiary: Color(0xFF003320),
    tertiaryContainer: Color(0xFF134E38),
    onTertiaryContainer: Color(0xFFC6FCE5),

    error: Color(0xFFF43F5E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A0D1A),
    onErrorContainer: Color(0xFFFFD9DF),

    surface: Color(0xFF0D0D0D),
    onSurface: Color(0xFFE4E4E7),
    onSurfaceVariant: Color(0xFF71717A),
    surfaceContainerLowest: Color(0xFF080808),
    surfaceContainerLow: Color(0xFF111111),
    surfaceContainer: Color(0xFF18181B),
    surfaceContainerHigh: Color(0xFF1F1F23),
    surfaceContainerHighest: Color(0xFF27272D),

    outline: Color(0xFF27272D),
    outlineVariant: Color(0xFF1F1F23),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0D0D0D),
    surfaceBright: Color(0xFF27272D),
    inverseSurface: Color(0xFFE4E4E7),
    inversePrimary: Color(0xFF059669),
  ),
  scaffoldBackgroundColor: const Color(0xFF0D0D0D),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF18181B),
    foregroundColor: Color(0xFFE4E4E7),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3ECF8E),
      foregroundColor: const Color(0xFF003320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF3ECF8E),
      foregroundColor: const Color(0xFF003320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF18181B),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF27272D)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF3ECF8E), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFF43F5E)),
    ),
  ),

  dividerColor: const Color(0xFF27272D),
  dividerTheme: const DividerThemeData(color: Color(0xFF27272D), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFF18181B),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFF27272D)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFE4E4E7)),
    displayMedium: TextStyle(color: Color(0xFFE4E4E7)),
    displaySmall: TextStyle(color: Color(0xFFE4E4E7)),
    headlineLarge: TextStyle(color: Color(0xFFE4E4E7)),
    headlineMedium: TextStyle(color: Color(0xFFE4E4E7)),
    headlineSmall: TextStyle(color: Color(0xFFE4E4E7)),
    titleLarge: TextStyle(color: Color(0xFFE4E4E7)),
    titleMedium: TextStyle(color: Color(0xFFE4E4E7)),
    titleSmall: TextStyle(color: Color(0xFFE4E4E7)),
    bodyLarge: TextStyle(color: Color(0xFFE4E4E7)),
    bodyMedium: TextStyle(color: Color(0xFF71717A)),
    bodySmall: TextStyle(color: Color(0xFF52525B)),
    labelLarge: TextStyle(color: Color(0xFFE4E4E7)),
    labelMedium: TextStyle(color: Color(0xFF71717A)),
    labelSmall: TextStyle(color: Color(0xFF52525B)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF3ECF8E),
    unselectedLabelColor: Color(0xFF71717A),
    indicatorColor: Color(0xFF3ECF8E),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF3ECF8E);
      return const Color(0xFF71717A);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF134E38);
      return const Color(0xFF27272D);
    }),
  ),
);

// ============================================================
// Supabase — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF059669),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFA7F3D0),
    onPrimaryContainer: Color(0xFF003320),
    primaryFixed: Color(0xFFA7F3D0),
    primaryFixedDim: Color(0xFF6EE7B7),

    secondary: Color(0xFF0D6B52),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF99F6E0),
    onSecondaryContainer: Color(0xFF001A10),
    secondaryFixed: Color(0xFF99F6E0),
    secondaryFixedDim: Color(0xFF5EEAD4),

    tertiary: Color(0xFF059669),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC6FCE5),
    onTertiaryContainer: Color(0xFF003320),

    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFD9DF),
    onErrorContainer: Color(0xFF40000C),

    surface: Color(0xFFFAFAFA),
    onSurface: Color(0xFF18181B),
    onSurfaceVariant: Color(0xFF52525B),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F4F5),
    surfaceContainer: Color(0xFFECECEE),
    surfaceContainerHigh: Color(0xFFE4E4E7),
    surfaceContainerHighest: Color(0xFFDCDCE0),

    outline: Color(0xFFD4D4D8),
    outlineVariant: Color(0xFFDCDCE0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDCDCE0),
    surfaceBright: Color(0xFFFAFAFA),
    inverseSurface: Color(0xFF27272D),
    inversePrimary: Color(0xFF6EE7B7),
  ),
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFECECEE),
    foregroundColor: Color(0xFF18181B),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFECECEE),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFD4D4D8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF059669), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),

  dividerColor: const Color(0xFFD4D4D8),
  dividerTheme: const DividerThemeData(color: Color(0xFFD4D4D8), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFFECECEE),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFD4D4D8)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF18181B)),
    displayMedium: TextStyle(color: Color(0xFF18181B)),
    displaySmall: TextStyle(color: Color(0xFF18181B)),
    headlineLarge: TextStyle(color: Color(0xFF18181B)),
    headlineMedium: TextStyle(color: Color(0xFF18181B)),
    headlineSmall: TextStyle(color: Color(0xFF18181B)),
    titleLarge: TextStyle(color: Color(0xFF18181B)),
    titleMedium: TextStyle(color: Color(0xFF18181B)),
    titleSmall: TextStyle(color: Color(0xFF18181B)),
    bodyLarge: TextStyle(color: Color(0xFF18181B)),
    bodyMedium: TextStyle(color: Color(0xFF52525B)),
    bodySmall: TextStyle(color: Color(0xFF71717A)),
    labelLarge: TextStyle(color: Color(0xFF18181B)),
    labelMedium: TextStyle(color: Color(0xFF52525B)),
    labelSmall: TextStyle(color: Color(0xFF71717A)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF059669),
    unselectedLabelColor: Color(0xFF52525B),
    indicatorColor: Color(0xFF059669),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF059669);
      return const Color(0xFF71717A);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF6EE7B7);
      return const Color(0xFFD4D4D8);
    }),
  ),
);
