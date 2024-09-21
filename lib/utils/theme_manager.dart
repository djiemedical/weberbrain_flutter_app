import 'package:flutter/material.dart';

class ThemeManager {
  static ThemeData getThemeForDevice(String deviceName) {
    final deviceType = deviceName.substring(4, 7);
    final isDarkTheme = deviceType == '678';

    return isDarkTheme
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.blueGrey[800],
            scaffoldBackgroundColor: Colors.grey[900],
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[600],
                foregroundColor: Colors.white,
              ),
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          );
  }
}
