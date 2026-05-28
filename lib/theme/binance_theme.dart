// ============================================================
// Binance-inspired Theme
// ============================================================
// Visual Theme: Bold Binance Yellow on monochrome, trading-floor urgency
// Atmosphere: Crypto exchange, data-dense, high-alert
// Inspired by: Binance
//
// Color Palette & Roles:
// ┌──────────────────────────┬───────────┬──────────────────────────────┐
// │ Token                    │ Hex       │ Role                         │
// ├──────────────────────────┼───────────┼──────────────────────────────┤
// │ primary                  │ #F0B90B   │ Binance Yellow, CTA, active  │
// │ onPrimary                │ #000000   │ Text / icons on primary      │
// │ primaryContainer         │ #332800   │ Subtle yellow bg             │
// │ secondary                │ #474D57   │ Steel gray — depth           │
// │ tertiary                 │ #FCD535   │ Bright yellow — sparse       │
// │ error                    │ #F6465D   │ Destructive / danger         │
// │ surface                  │ #0B0E11   │ Default surface bg           │
// │ onSurface                │ #EAECEF   │ Primary text                 │
// │ onSurfaceVariant         │ #848E9C   │ Secondary / muted text       │
// │ surfaceContainerLowest   │ #050608   │ Deepest void                 │
// │ surfaceContainerLow      │ #0B0E11   │ Low elevation                │
// │ surfaceContainer         │ #12161C   │ Card / input bg              │
// │ surfaceContainerHigh     │ #1A1F26   │ Elevated (drawer, sidebar)   │
// │ surfaceContainerHighest  │ #232830   │ Highest elevation (dialogs)  │
// │ outline                  │ #2B3139   │ Borders, dividers            │
// └──────────────────────────┴───────────┴──────────────────────────────┘
//
// Do:
//   ✓ Yellow reserved for actionable elements — buy, trade, confirm
//   ✓ Data-dense layouts, price tables, order books
//   ✓ Clear green/red semantics for up/down
// Don't:
//   ✗ Never use yellow as decoration — it means action
//   ✗ Avoid rounded corners above 4px — precision matters
// ============================================================

import 'package:flutter/material.dart';

const Color _binanceSeed = Color(0xFFF0B90B);

// ============================================================
// Binance — Dark Theme
// ============================================================
final ThemeData dark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Robot',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFF0B90B),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF332800),
    onPrimaryContainer: Color(0xFFFFE88A),
    primaryFixed: Color(0xFFFFE88A),
    primaryFixedDim: Color(0xFFFCD535),

    secondary: Color(0xFF474D57),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF232830),
    onSecondaryContainer: Color(0xFFB8BDC4),
    secondaryFixed: Color(0xFFB8BDC4),
    secondaryFixedDim: Color(0xFF848E9C),

    tertiary: Color(0xFFFCD535),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF403400),
    onTertiaryContainer: Color(0xFFFFF0A0),

    error: Color(0xFFF6465D),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3E0A14),
    onErrorContainer: Color(0xFFFFDAD6),

    surface: Color(0xFF0B0E11),
    onSurface: Color(0xFFEAECEF),
    onSurfaceVariant: Color(0xFF848E9C),
    surfaceContainerLowest: Color(0xFF050608),
    surfaceContainerLow: Color(0xFF0B0E11),
    surfaceContainer: Color(0xFF12161C),
    surfaceContainerHigh: Color(0xFF1A1F26),
    surfaceContainerHighest: Color(0xFF232830),

    outline: Color(0xFF2B3139),
    outlineVariant: Color(0xFF1A1F26),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFF0B0E11),
    surfaceBright: Color(0xFF232830),
    inverseSurface: Color(0xFFEAECEF),
    inversePrimary: Color(0xFFC99B00),
  ),
  scaffoldBackgroundColor: const Color(0xFF0B0E11),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF12161C),
    foregroundColor: Color(0xFFEAECEF),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF0B90B),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFF0B90B),
      foregroundColor: const Color(0xFF000000),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF12161C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFF2B3139)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFF0B90B), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFF6465D)),
    ),
  ),

  dividerColor: const Color(0xFF2B3139),
  dividerTheme: const DividerThemeData(color: Color(0xFF2B3139), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFF12161C),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(color: Color(0xFF2B3139)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFFEAECEF), fontWeight: FontWeight.w600),
    displayMedium: TextStyle(color: Color(0xFFEAECEF), fontWeight: FontWeight.w600),
    displaySmall: TextStyle(color: Color(0xFFEAECEF)),
    headlineLarge: TextStyle(color: Color(0xFFEAECEF)),
    headlineMedium: TextStyle(color: Color(0xFFEAECEF)),
    headlineSmall: TextStyle(color: Color(0xFFEAECEF)),
    titleLarge: TextStyle(color: Color(0xFFEAECEF)),
    titleMedium: TextStyle(color: Color(0xFFEAECEF)),
    titleSmall: TextStyle(color: Color(0xFFEAECEF)),
    bodyLarge: TextStyle(color: Color(0xFFEAECEF)),
    bodyMedium: TextStyle(color: Color(0xFF848E9C)),
    bodySmall: TextStyle(color: Color(0xFF5E6670)),
    labelLarge: TextStyle(color: Color(0xFFEAECEF)),
    labelMedium: TextStyle(color: Color(0xFF848E9C)),
    labelSmall: TextStyle(color: Color(0xFF5E6670)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFF0B90B),
    unselectedLabelColor: Color(0xFF848E9C),
    indicatorColor: Color(0xFFF0B90B),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFF0B90B);
      return const Color(0xFF848E9C);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFF403400);
      return const Color(0xFF2B3139);
    }),
  ),
);

// ============================================================
// Binance — Light Theme
// ============================================================
final ThemeData light = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansCJK',
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFC99B00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFE88A),
    onPrimaryContainer: Color(0xFF332800),
    primaryFixed: Color(0xFFFFE88A),
    primaryFixedDim: Color(0xFFFCD535),

    secondary: Color(0xFF474D57),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E3E8),
    onSecondaryContainer: Color(0xFF1A1F26),
    secondaryFixed: Color(0xFFE0E3E8),
    secondaryFixedDim: Color(0xFFC5CAD2),

    tertiary: Color(0xFFC99B00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFF0A0),
    onTertiaryContainer: Color(0xFF332800),

    error: Color(0xFFD3163C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF40000C),

    surface: Color(0xFFF5F6F8),
    onSurface: Color(0xFF12161C),
    onSurfaceVariant: Color(0xFF474D57),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF0F1F4),
    surfaceContainer: Color(0xFFEAECEF),
    surfaceContainerHigh: Color(0xFFE4E6EA),
    surfaceContainerHighest: Color(0xFFDEE0E4),

    outline: Color(0xFFC5CAD2),
    outlineVariant: Color(0xFFDEE0E4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceDim: Color(0xFFDEE0E4),
    surfaceBright: Color(0xFFF5F6F8),
    inverseSurface: Color(0xFF232830),
    inversePrimary: Color(0xFFFCD535),
  ),
  scaffoldBackgroundColor: const Color(0xFFF5F6F8),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEAECEF),
    foregroundColor: Color(0xFF12161C),
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFC99B00),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFEAECEF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFC5CAD2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFC99B00), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: Color(0xFFD3163C)),
    ),
  ),

  dividerColor: const Color(0xFFC5CAD2),
  dividerTheme: const DividerThemeData(color: Color(0xFFC5CAD2), thickness: 1),

  cardTheme: CardThemeData(
    color: const Color(0xFFEAECEF),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(color: Color(0xFFC5CAD2)),
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF12161C), fontWeight: FontWeight.w600),
    displayMedium: TextStyle(color: Color(0xFF12161C), fontWeight: FontWeight.w600),
    displaySmall: TextStyle(color: Color(0xFF12161C)),
    headlineLarge: TextStyle(color: Color(0xFF12161C)),
    headlineMedium: TextStyle(color: Color(0xFF12161C)),
    headlineSmall: TextStyle(color: Color(0xFF12161C)),
    titleLarge: TextStyle(color: Color(0xFF12161C)),
    titleMedium: TextStyle(color: Color(0xFF12161C)),
    titleSmall: TextStyle(color: Color(0xFF12161C)),
    bodyLarge: TextStyle(color: Color(0xFF12161C)),
    bodyMedium: TextStyle(color: Color(0xFF474D57)),
    bodySmall: TextStyle(color: Color(0xFF6B717A)),
    labelLarge: TextStyle(color: Color(0xFF12161C)),
    labelMedium: TextStyle(color: Color(0xFF474D57)),
    labelSmall: TextStyle(color: Color(0xFF6B717A)),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFFC99B00),
    unselectedLabelColor: Color(0xFF474D57),
    indicatorColor: Color(0xFFC99B00),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFC99B00);
      return const Color(0xFF848E9C);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return const Color(0xFFFCD535);
      return const Color(0xFFC5CAD2);
    }),
  ),
);
