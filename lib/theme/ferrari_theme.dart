// ============================================================
// Ferrari-inspired Theme
// ============================================================
// Visual Theme: Chiaroscuro black-white editorial, extreme sparseness
// Atmosphere: Luxury automotive, drama, speed
// Inspired by: Ferrari
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #FF2800   │ Ferrari Red, CTA, accent     │
// │ onPrimary                │ #FFFFFF   │ Text / icons on primary      │
// │ primaryContainer         │ #3E0000   │ Subtle red bg                │
// │ secondary                │ #C0C0C0   │ Silver — depth               │
// │ tertiary                 │ #FF6B3D   │ Bright red — sparse glow     │
// │ error                    │ #DC0000   │ Destructive / danger         │
// │ surface                  │ #0A0A0A   │ Default surface bg           │
// │ onSurface                │ #F0F0F0   │ Primary text                 │
// │ onSurfaceVariant         │ #909090   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #000000   │ Deepest black                │
// │ surfaceContainerLow      │ #0D0D0D   │ Low elevation                │
// │ surfaceContainer         │ #141414   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1C1C1C   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #262626   │ Highest elevation (dialogs)  │
// │ outline                  │ #2A2A2A   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Red used with extreme sparseness — one CTA per page max
//   ✓ Black and white dominates — red is a signal, not a decoration
//   ✓ Editorial layouts with dramatic contrast
// Don't:
//   ✗ Never use red for non-critical UI elements
//   ✗ Avoid colored surfaces — keep backgrounds pure black
// ============================================================

import 'package:flutter/material.dart';

const Color _ferrariSeed = Color(0xFFFF2800);

// ============================================================
// Ferrari — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Robot',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFF2800),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3E0000),
    onPrimaryContainer: Color(0xFFFFDAD1),
    primaryFixed: Color(0xFFFFDAD1),
    primaryFixedDim: Color(0xFFFF6B3D),

    secondary: Color(0xFFC0C0C0),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF262626),
    onSecondaryContainer: Color(0xFFD0D0D0),
    secondaryFixed: Color(0xFFD0D0D0),
    secondaryFixedDim: Color(0xFFA0A0A0),

    tertiary: Color(0xFFFF6B3D),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF4A0D00),
    onTertiaryContainer: Color(0xFFFFDAD1),

    error: Color(0xFFDC0000),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3E0000),
    onErrorContainer: Color(0xFFFFDAD1),

    surface: Color(0xFF0A0A0A),
    onSurface: Color(0xFFF0F0F0),
    onSurfaceVariant: Color(0xFF909090),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0D0D0D),
    surfaceContainer: Color(0xFF141414),
    surfaceContainerHigh: Color(0xFF1C1C1C),
    surfaceContainerHighest: Color(0xFF262626),

    outline: Color(0xFF2A2A2A),
    outlineVariant: Color(0xFF1C1C1C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0A0A0A),
    surfaceBright: Color(0xFF262626),
    inverseSurface: Color(0xFFF0F0F0),
    inversePrimary: Color(0xFFCC2000),
  ),
  scaffoldBackgroundColor: const Color(0xFF0A0A0A),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF141414),
    foregroundColor: Color(0xFFF0F0F0),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF2800),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFFF2800),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF141414),
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
      borderSide: BorderSide(color: Color(0xFFFF2800), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFDC0000)),
    ),
  ),

  dividerColor: const Color(0xFF2A2A2A),
  dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFF141414),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(color: Color(0xFF2A2A2A)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFFF0F0F0)),
    headlineLarge: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFFF0F0F0)),
    headlineSmall: TextStyle(color: Color(0xFFF0F0F0)),
    titleLarge: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Color(0xFFF0F0F0)),
    titleSmall: TextStyle(color: Color(0xFFF0F0F0)),
    bodyLarge: TextStyle(color: Color(0xFFF0F0F0)),
    bodyMedium: TextStyle(color: Color(0xFF909090)),
    bodySmall: TextStyle(color: Color(0xFF6A6A6A)),
    labelLarge: TextStyle(color: Color(0xFFF0F0F0)),
    labelMedium: TextStyle(color: Color(0xFF909090)),
    labelSmall: TextStyle(color: Color(0xFF6A6A6A)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFFF2800),
    unselectedLabelColor: Color(0xFF909090),
    indicatorColor: Color(0xFFFF2800),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFF2800);
      return const Color(0xFF909090);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF4A0D00);
      return const Color(0xFF2A2A2A);
    }),
  ),
);

// ============================================================
// Ferrari — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFCC2000),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDAD1),
    onPrimaryContainer: Color(0xFF3E0000),
    primaryFixed: Color(0xFFFFDAD1),
    primaryFixedDim: Color(0xFFFF6B3D),

    secondary: Color(0xFF606060),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE5E5E5),
    onSecondaryContainer: Color(0xFF1C1C1C),
    secondaryFixed: Color(0xFFE5E5E5),
    secondaryFixedDim: Color(0xFFCCCCCC),

    tertiary: Color(0xFFE04000),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDAD1),
    onTertiaryContainer: Color(0xFF3E0000),

    error: Color(0xFFDC0000),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD1),
    onErrorContainer: Color(0xFF3E0000),

    surface: Color(0xFFF8F8F8),
    onSurface: Color(0xFF0A0A0A),
    onSurfaceVariant: Color(0xFF606060),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2F2F2),
    surfaceContainer: Color(0xFFECECEC),
    surfaceContainerHigh: Color(0xFFE5E5E5),
    surfaceContainerHighest: Color(0xFFDFDFDF),

    outline: Color(0xFFCCCCCC),
    outlineVariant: Color(0xFFDFDFDF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDFDFDF),
    surfaceBright: Color(0xFFF8F8F8),
    inverseSurface: Color(0xFF262626),
    inversePrimary: Color(0xFFFF6B3D),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F8F8),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFECECEC),
    foregroundColor: Color(0xFF0A0A0A),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFCC2000),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFECECEC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFCCCCCC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFCC2000), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFDC0000)),
    ),
  ),

  dividerColor: const Color(0xFFCCCCCC),
  dividerTheme: const DividerThemeData(color: Color(0xFFCCCCCC), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFFECECEC),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w300),
    displayMedium: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w300),
    displaySmall: TextStyle(color: Color(0xFF0A0A0A)),
    headlineLarge: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w300),
    headlineMedium: TextStyle(color: Color(0xFF0A0A0A)),
    headlineSmall: TextStyle(color: Color(0xFF0A0A0A)),
    titleLarge: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Color(0xFF0A0A0A)),
    titleSmall: TextStyle(color: Color(0xFF0A0A0A)),
    bodyLarge: TextStyle(color: Color(0xFF0A0A0A)),
    bodyMedium: TextStyle(color: Color(0xFF606060)),
    bodySmall: TextStyle(color: Color(0xFF808080)),
    labelLarge: TextStyle(color: Color(0xFF0A0A0A)),
    labelMedium: TextStyle(color: Color(0xFF606060)),
    labelSmall: TextStyle(color: Color(0xFF808080)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFCC2000),
    unselectedLabelColor: Color(0xFF606060),
    indicatorColor: Color(0xFFCC2000),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFCC2000);
      return const Color(0xFF909090);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFF6B3D);
      return const Color(0xFFCCCCCC);
    }),
  ),
);
