import 'package:flutter/material.dart';

import 'screens/role_selection_screen.dart';

class HyopeApp extends StatelessWidget {
  const HyopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HYOPE',
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F80FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
