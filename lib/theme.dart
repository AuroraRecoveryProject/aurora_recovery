import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8B5CF6),
    onPrimary: Colors.white,
    secondary: Color(0xFFB794F4),
    onSecondary: Colors.black,
    error: Color(0xFFFF4D6D),
    onError: Colors.white,
    surface: Color(0xFF0E0B14),
    onSurface: Color(0xFFF3F0FF),
    surfaceContainerLowest: Color(0xFF0A0810),
    surfaceContainerLow: Color(0xFF14101C),
    surfaceContainer: Color(0xFF1A1625),
    surfaceContainerHigh: Color(0xFF221C30),
    surfaceContainerHighest: Color(0xFF2A2340),
  ),
  scaffoldBackgroundColor: const Color(0xFF0E0B14),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1625),
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: const CardTheme(
    color: Color(0xFF1A1625),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF8B5CF6),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1A1625),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF2F2840)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
    ),
  ),
  dividerColor: const Color(0xFF2F2840),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFF3F0FF)),
    bodyMedium: TextStyle(color: Color(0xFFB8AEE6)),
  ),
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF7C3AED),
    onPrimary: Colors.white,
    secondary: Color(0xFFA78BFA),
    onSecondary: Colors.white,
    error: Color(0xFFD32F6A),
    onError: Colors.white,
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF221C30),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F6FF),
    surfaceContainer: Color(0xFFF3F0FF),
    surfaceContainerHigh: Color(0xFFECE8FF),
    surfaceContainerHighest: Color(0xFFE4DEFF),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF3F0FF),
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: const CardTheme(
    color: Color(0xFFF3F0FF),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7C3AED),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF3F0FF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFDAD3FF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF7C3AED), width: 1.5),
    ),
  ),
  dividerColor: const Color(0xFFDAD3FF),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF221C30)),
    bodyMedium: TextStyle(color: Color(0xFF6B5CA5)),
  ),
);
