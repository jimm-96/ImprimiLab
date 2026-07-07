import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'state/theme_state.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await appState.init();
  } catch (e) {
    debugPrint("Error al inicializar appState: $e");
  }

  try {
    await themeState.init();
  } catch (e) {
    debugPrint("Error al inicializar themeState: $e");
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint("Error al inicializar NotificationService: $e");
  }

  runApp(const ImpriLabApp());
}

class ImpriLabApp extends StatelessWidget {
  const ImpriLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeState,
      builder: (context, _) {
        return MaterialApp(
          title: 'ImpriLab',
          debugShowCheckedModeBanner: false,
          theme: themeState.lightTheme,
          darkTheme: themeState.darkTheme,
          themeMode: themeState.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
