import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Paletas de color disponibles ─────────────────────────────────────────────

class AppColorPalette {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;

  const AppColorPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
  });
}

const List<AppColorPalette> kAvailablePalettes = [
  AppColorPalette(
    id: 'cyan',
    name: 'Cyan Tech',
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFFFF6B35),
  ),
  AppColorPalette(
    id: 'emerald',
    name: 'Esmeralda',
    primary: Color(0xFF00E676),
    secondary: Color(0xFFFF6B35),
  ),
  AppColorPalette(
    id: 'violet',
    name: 'Violeta',
    primary: Color(0xFFD500F9),
    secondary: Color(0xFFFFD740),
  ),
  AppColorPalette(
    id: 'amber',
    name: 'Ámbar',
    primary: Color(0xFFFFAB00),
    secondary: Color(0xFF00E5FF),
  ),
  AppColorPalette(
    id: 'rose',
    name: 'Rosa Neon',
    primary: Color(0xFFFF4081),
    secondary: Color(0xFF64FFDA),
  ),
  AppColorPalette(
    id: 'sky',
    name: 'Azul Cielo',
    primary: Color(0xFF40C4FF),
    secondary: Color(0xFFFF6E40),
  ),
];

// ─── Estado del tema (singleton observable) ───────────────────────────────────

class ThemeState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _paletteId = 'cyan';

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  AppColorPalette get palette =>
      kAvailablePalettes.firstWhere(
        (p) => p.id == _paletteId,
        orElse: () => kAvailablePalettes.first,
      );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _paletteId = prefs.getString('theme_palette') ?? 'cyan';
    final isDarkPref = prefs.getBool('theme_dark') ?? true;
    _themeMode = isDarkPref ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', isDark);
    notifyListeners();
  }

  Future<void> setPalette(String paletteId) async {
    _paletteId = paletteId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_palette', paletteId);
    notifyListeners();
  }

  // ── Generadores de ThemeData ─────────────────────────────────────────────

  ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    scaffoldBg: const Color(0xFF0F172A),
    surfaceColor: const Color(0xFF1E293B),
    cardColor: const Color(0xFF1E293B),
    appBarBg: const Color(0xFF0F172A),
  );

  ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBg: const Color(0xFFF1F5F9),
    surfaceColor: Colors.white,
    cardColor: Colors.white,
    appBarBg: Colors.white,
  );

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color cardColor,
    required Color appBarBg,
  }) {
    final p = palette;
    final isDarkMode = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: p.primary,
      cardColor: cardColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: isDarkMode ? Colors.black : Colors.white,
        secondary: p.secondary,
        onSecondary: isDarkMode ? Colors.black : Colors.white,
        error: const Color(0xFFEF476F),
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: isDarkMode ? Colors.white : const Color(0xFF1E293B),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: p.primary),
        titleTextStyle: TextStyle(
          color: p.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        labelStyle: TextStyle(color: p.primary.withAlpha(200)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: isDarkMode ? Colors.black : Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary.withAlpha(128) : null,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceColor),
        ),
      ),
    );
  }
}

// Instancia global
final themeState = ThemeState();
