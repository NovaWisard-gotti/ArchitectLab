import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/home_screen.dart';

class DatabaseArchitectLabApp extends StatelessWidget {
  const DatabaseArchitectLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Architect Lab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const HomeScreen(),
    );
  }
}
