import 'package:flutter/material.dart';

const deepBlue = Color(0xFF0B3C5D);
const teal = Color(0xFF14A3A3);
const darkGrey = Color(0xFF2B2F36);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: deepBlue).copyWith(primary: deepBlue, secondary: teal),
  scaffoldBackgroundColor: Colors.white,
  textTheme: ThemeData.light().textTheme.apply(bodyColor: darkGrey, displayColor: darkGrey),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: deepBlue, elevation: 0),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
);
