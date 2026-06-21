import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'screens/main_screen.dart';

/// Titik masuk utama aplikasi SmartPay.
void main() {
  runApp(const SmartPayApp());
}

class SmartPayApp extends StatelessWidget {
  const SmartPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}

