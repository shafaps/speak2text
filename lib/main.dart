import 'package:flutter/material.dart';
import 'package:speak2text/home.dart';

void main() {
  runApp(NoteApp(isDarkMode: true));
}

class NoteApp extends StatelessWidget {
  final bool isDarkMode;

  NoteApp({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NoteList(),
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }
}
