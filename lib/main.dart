import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.init();
  runApp(const ImpriLabApp());
}

class ImpriLabApp extends StatelessWidget {
  const ImpriLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImpriLab',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.cyanAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.orangeAccent,
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      home: appState.setupCompleted
          ? const DashboardScreen()
          : const OnboardingScreen(),
    );
  }
}
