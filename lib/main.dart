import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const EzReportApp());
}

class EzReportApp extends StatelessWidget {
  const EzReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
