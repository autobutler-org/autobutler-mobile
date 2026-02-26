import 'package:flutter/material.dart';
import 'package:autobutler/pages/file_browser_page.dart';

void main() {
  runApp(const AutobutlerApp());
}

class AutobutlerApp extends StatelessWidget {
  const AutobutlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Autobutler Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070D19),
        useMaterial3: true,
      ),
      home: const FileBrowserPage(),
    );
  }
}
