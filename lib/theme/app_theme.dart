import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1DB954), // Spotify green
    scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(0, 0, 0, 1),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(154, 0, 0, 0),
      selectedItemColor: Color(0xFF1DB954),
      unselectedItemColor: Colors.grey,
    ),
  );
}
