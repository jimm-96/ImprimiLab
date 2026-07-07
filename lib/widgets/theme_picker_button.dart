import 'package:flutter/material.dart';
import '../state/theme_state.dart';

/// Botón del AppBar que abre el selector de tema (paleta + modo claro/oscuro).
class ThemePickerButton extends StatelessWidget {
  const ThemePickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeState,
      builder: (context, _) {
        return IconButton(
          icon: Icon(
            Icons.palette_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Personalizar tema',
          onPressed: () => _showThemePicker(context),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ThemePickerSheet(),
    );
  }
}

// ─── Hoja inferior del selector de tema ──────────────────────────────────────

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white54 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: ListenableBuilder(
        listenable: themeState,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subtextColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                'Personalizar Apariencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige tu paleta de color y modo de visualización',
                style: TextStyle(fontSize: 13, color: subtextColor),
              ),

              const SizedBox(height: 24),

              // ── Toggle modo claro/oscuro ──────────────────────────────
              Text(
                'MODO DE VISUALIZACIÓN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 12),

              _ThemeModeToggle(isDark: isDark, textColor: textColor),

              const SizedBox(height: 28),

              // ── Paletas de color ──────────────────────────────────────
              Text(
                'PALETA DE COLOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: kAvailablePalettes.length,
                itemBuilder: (context, index) {
                  final palette = kAvailablePalettes[index];
                  final isSelected = themeState.palette.id == palette.id;
                  return _PaletteCard(
                    palette: palette,
                    isSelected: isSelected,
                    isDark: isDark,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

// ─── Toggle modo claro/oscuro ─────────────────────────────────────────────────

class _ThemeModeToggle extends StatelessWidget {
  final bool isDark;
  final Color textColor;

  const _ThemeModeToggle({required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withAlpha(40),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeButton(
            icon: Icons.dark_mode_rounded,
            label: 'Oscuro',
            isActive: isDark,
            primary: primary,
            textColor: textColor,
            onTap: () {
              if (!isDark) themeState.toggleThemeMode();
            },
          ),
          _ModeButton(
            icon: Icons.light_mode_rounded,
            label: 'Claro',
            isActive: !isDark,
            primary: primary,
            textColor: textColor,
            onTap: () {
              if (isDark) themeState.toggleThemeMode();
            },
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color primary;
  final Color textColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.primary,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.black : textColor.withAlpha(153),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.black : textColor.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tarjeta de paleta ────────────────────────────────────────────────────────

class _PaletteCard extends StatelessWidget {
  final AppColorPalette palette;
  final bool isSelected;
  final bool isDark;

  const _PaletteCard({
    required this.palette,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => themeState.setPalette(palette.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? palette.primary
                : palette.primary.withAlpha(40),
            width: isSelected ? 2.5 : 1,
          ),
          color: isDark
              ? palette.primary.withAlpha(isSelected ? 30 : 15)
              : palette.primary.withAlpha(isSelected ? 25 : 10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.primary.withAlpha(60),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Swatches de color
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ColorSwatch(color: palette.primary, size: 20),
                const SizedBox(width: 4),
                _ColorSwatch(color: palette.secondary, size: 14),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              palette.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? palette.primary
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Icon(Icons.check_circle_rounded, size: 14, color: palette.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final double size;
  const _ColorSwatch({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
