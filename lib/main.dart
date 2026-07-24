import 'package:flutter/material.dart';
import 'package:tatry_kamera/screens/home_page.dart';

import 'data/colors.dart';

void main() {
  runApp(const TOPRCamsApp());
}

class TOPRCamsApp extends StatelessWidget {
  const TOPRCamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData.light().copyWith(
        primaryColor: darkGreen,
        appBarTheme: AppBarTheme(
          backgroundColor: darkGreen,
          titleTextStyle: const TextStyle(color: white, fontSize: 20),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: darkGreen,
          unselectedLabelColor: Colors.black87,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: darkGreen, width: 2),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkGreen,
          foregroundColor: white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: darkGreen,
        scaffoldBackgroundColor: black,
        appBarTheme: AppBarTheme(
          backgroundColor: darkGreen,
          titleTextStyle: const TextStyle(color: white, fontSize: 20),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: green,
          unselectedLabelColor: white,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: darkGreen, width: 2),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkGreen,
          foregroundColor: white,
        ),
      ),
      home: const TOPRCamsHomePage(),
    );
  }
}
