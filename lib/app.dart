import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      // 쿠퍼티노 날짜·시간 피커가 로케일을 보고 표기를 정한다. 이 설정이 없으면
      // 영어로 떠서 "AM/PM", "August"가 나온다.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
      home: const RoleSelectionScreen(),
    );
  }
}