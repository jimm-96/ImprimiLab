import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class IntroSlidesScreen extends StatefulWidget {
  const IntroSlidesScreen({super.key});

  @override
  State<IntroSlidesScreen> createState() => _IntroSlidesScreenState();
}

class _IntroSlidesScreenState extends State<IntroSlidesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  void _goToNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _startApp();
    }
  }

  void _startApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1A),
      body: Stack(
        children: [
          // ── Fondo con gradiente decorativo ────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPainter()),
          ),

          // ── Slides ────────────────────────────────────────────────────
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: const [
              _Slide1(),
              _Slide2(),
              _Slide3(),
            ],
          ),

          // ── Controles inferiores ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomControls(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onNext: _goToNext,
              onSkip: _startApp,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fondo decorativo con formas geométricas ─────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintCircle1 = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.12),
      180,
      paintCircle1,
    );

    final paintCircle2 = Paint()
      ..color = const Color(0xFFFF6B35).withAlpha(10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      140,
      paintCircle2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Controles inferiores (dots + botón) ──────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _BottomControls({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLast = currentPage == totalPages - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == currentPage
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF00E5FF).withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          // Botón principal
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF060D1A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isLast ? 'Configurar mi Taller' : 'Siguiente',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Saltar introducción',
                style: TextStyle(
                  color: Colors.white.withAlpha(102),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Slide 1: ¿Qué es ImpriLab? ──────────────────────────────────────────────

class _Slide1 extends StatelessWidget {
  const _Slide1();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo circular con gradiente
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00E5FF).withAlpha(77),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withAlpha(51),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/Logo_ImpriLab.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF80FFEA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'ImpriLab',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Etiqueta de sección
          _SectionLabel(label: '¿Qué es ImpriLab?'),
          const SizedBox(height: 16),

          const Text(
            'Un ecosistema multiplataforma diseñado específicamente para makers, talleres y emprendimientos de manufactura aditiva.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No es una simple calculadora de precio por gramo. ImpriLab es un software integral capaz de computar con precisión matemática:',
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.white.withAlpha(178),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Features list
          _FeatureItem(
            icon: Icons.electrical_services_rounded,
            color: const Color(0xFFFFD166),
            title: 'Desgaste eléctrico exacto',
            description: 'Consumo real de energía por impresión.',
          ),
          _FeatureItem(
            icon: Icons.precision_manufacturing_rounded,
            color: const Color(0xFF06D6A0),
            title: 'Depreciación de hardware',
            description: 'Amortización automática por hora de uso de cada máquina.',
          ),
          _FeatureItem(
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF00E5FF),
            title: 'Consumo de materiales',
            description: 'Gramos de filamento o mililitros de resina con precisión.',
          ),
          _FeatureItem(
            icon: Icons.handyman_rounded,
            color: const Color(0xFFEF476F),
            title: 'Mano de obra y post-procesado',
            description: 'Tarifas personalizadas por tipo de trabajo.',
          ),
        ],
      ),
    );
  }
}

// ─── Slide 2: Flujo de trabajo ────────────────────────────────────────────────

class _Slide2 extends StatelessWidget {
  const _Slide2();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2F1A), Color(0xFF0D1F0D)],
                ),
                border: Border.all(
                  color: const Color(0xFF06D6A0).withAlpha(77),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.route_rounded,
                size: 36,
                color: Color(0xFF06D6A0),
              ),
            ),
          ),
          const SizedBox(height: 48),

          _SectionLabel(label: '¿Cómo se usa?'),
          const SizedBox(height: 16),

          const Text(
            'El camino del maker en 3 pasos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          _WorkflowStep(
            step: 1,
            color: const Color(0xFF00E5FF),
            icon: Icons.devices_other_rounded,
            title: 'Registra tu equipamiento e insumos',
            description:
                'Agrega tus impresoras FDM o de resina con su potencia, costo y vida útil. Luego carga tu inventario: bobinas de filamento o botellas de resina con su peso total y costo.',
          ),
          _StepConnector(),

          _WorkflowStep(
            step: 2,
            color: const Color(0xFF06D6A0),
            icon: Icons.tune_rounded,
            title: 'Define perfiles de laminación',
            description:
                'Configura tus perfiles de Slicer con variables clave: altura de capa, porcentaje de relleno, tiempos de exposición para resina, velocidades y más.',
          ),
          _StepConnector(),

          _WorkflowStep(
            step: 3,
            color: const Color(0xFFFFD166),
            icon: Icons.business_center_rounded,
            title: 'Organiza proyectos comerciales',
            description:
                'Crea proyectos con múltiples camas de impresión y piezas híbridas. Mueve el slider de ganancia en tiempo real para obtener el precio de venta sugerido al instante.',
          ),

          const SizedBox(height: 24),
          // Highlight del slider
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD166).withAlpha(51),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFFFD166),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El slider de margen de ganancia actualiza el precio de venta en tiempo real sin recalcular nada.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withAlpha(204),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 3: Inventario Inteligente y Alertas ────────────────────────────────

class _Slide3 extends StatelessWidget {
  const _Slide3();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A1A2A), Color(0xFF1A0D1A)],
                ),
                border: Border.all(
                  color: const Color(0xFFEF476F).withAlpha(77),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 36,
                color: Color(0xFFEF476F),
              ),
            ),
          ),
          const SizedBox(height: 48),

          _SectionLabel(label: 'Inventario y Alertas', color: const Color(0xFFEF476F)),
          const SizedBox(height: 16),

          const Text(
            'Control inteligente que trabaja contigo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ImpriLab tiene un cerebro deductivo automatizado que mantiene tu inventario siempre actualizado.',
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.white.withAlpha(178),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // Stock deductivo
          _AlertCard(
            icon: Icons.sync_alt_rounded,
            color: const Color(0xFF06D6A0),
            title: 'Inventario en tiempo real',
            description:
                'El sistema descuenta y reembolsa gramos de filamento o mililitros de resina automáticamente según el estado de cada pedido. Sin cálculos manuales.',
          ),
          const SizedBox(height: 16),

          // Recordatorios diarios
          _AlertCard(
            icon: Icons.alarm_rounded,
            color: const Color(0xFFFFD166),
            title: 'Recordatorios diarios de stock',
            description:
                'Recibe alertas automáticas cada mañana para verificar que tienes suficiente material antes de iniciar impresiones largas.',
          ),
          const SizedBox(height: 16),

          // Alertas de deadline
          _AlertCard(
            icon: Icons.event_busy_rounded,
            color: const Color(0xFFEF476F),
            title: 'Alertas de fecha límite',
            description:
                'El sistema programa recordatorios exactos para que ningún proyecto cruce la fecha de entrega comprometida con el cliente.',
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF060D1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: const Color(0xFF00E5FF).withAlpha(204),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todas las notificaciones son locales: no requieren internet ni servidores externos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withAlpha(178),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets de soporte reutilizables ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({
    required this.label,
    this.color = const Color(0xFF00E5FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: color,
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(51)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withAlpha(153),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final int step;
  final Color color;
  final IconData icon;
  final String title;
  final String description;

  const _WorkflowStep({
    required this.step,
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(102), width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withAlpha(153),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 23, top: 0, bottom: 0),
      child: Container(
        width: 2,
        height: 24,
        color: Colors.white.withAlpha(25),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withAlpha(153),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
