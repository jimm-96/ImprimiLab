import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCountry = 'chile';
  String _selectedLanguage = 'es';
  String _selectedCurrency = 'CLP';
  final _taxCtrl = TextEditingController(text: '19');
  final _customCurrencyCtrl = TextEditingController();
  final _kwhCtrl = TextEditingController(text: '150');

  void _onCountryChanged(String? countryKey) {
    if (countryKey == null) return;
    setState(() {
      _selectedCountry = countryKey;
      switch (countryKey) {
        case 'chile':
          _selectedLanguage = 'es';
          _selectedCurrency = 'CLP';
          _taxCtrl.text = '19';
          _kwhCtrl.text = '150';
          break;
        case 'argentina':
          _selectedLanguage = 'es';
          _selectedCurrency = 'ARS';
          _taxCtrl.text = '21';
          _kwhCtrl.text = '60';
          break;
        case 'spain':
          _selectedLanguage = 'es';
          _selectedCurrency = 'EUR';
          _taxCtrl.text = '21';
          _kwhCtrl.text = '0.22';
          break;
        case 'mexico':
          _selectedLanguage = 'es';
          _selectedCurrency = 'MXN';
          _taxCtrl.text = '16';
          _kwhCtrl.text = '2.0';
          break;
        case 'usa':
          _selectedLanguage = 'en';
          _selectedCurrency = 'USD';
          _taxCtrl.text = '0';
          _kwhCtrl.text = '0.16';
          break;
        case 'custom':
          // Custom settings - let user define
          _selectedLanguage = 'es';
          _selectedCurrency = 'USD';
          _taxCtrl.text = '0';
          _kwhCtrl.text = '0.15';
          _customCurrencyCtrl.text = '';
          break;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final String finalCurrency = _selectedCurrency == 'CUSTOM'
        ? _customCurrencyCtrl.text.toUpperCase().trim()
        : _selectedCurrency;

    final double finalTax = double.tryParse(_taxCtrl.text) ?? 0.0;
    final double finalKwh = double.tryParse(_kwhCtrl.text.replaceAll(',', '.')) ?? 0.15;

    String countryName = "Chile";
    switch (_selectedCountry) {
      case 'chile':
        countryName = "Chile";
        break;
      case 'argentina':
        countryName = "Argentina";
        break;
      case 'spain':
        countryName = "España";
        break;
      case 'mexico':
        countryName = "México";
        break;
      case 'usa':
        countryName = "Estados Unidos";
        break;
      case 'custom':
        countryName = "Personalizado";
        break;
    }

    appState.updateSettings(
      countryVal: countryName,
      languageVal: _selectedLanguage,
      currencyVal: finalCurrency,
      taxRateVal: finalTax,
      electricityPriceKwhVal: finalKwh,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icono decorativo premium
                const Icon(
                  Icons.language_outlined,
                  size: 80,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Bienvenido a ImpriLab!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Configuremos los datos principales de tu taller 3D para adaptar la app a tus necesidades regionales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),

                // Card de Configuración
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // País
                        const Text(
                          'Selecciona tu País',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          items: const [
                            DropdownMenuItem(
                              value: 'chile',
                              child: Text('Chile 🇨🇱'),
                            ),
                            DropdownMenuItem(
                              value: 'argentina',
                              child: Text('Argentina 🇦🇷'),
                            ),
                            DropdownMenuItem(
                              value: 'spain',
                              child: Text('España 🇪🇸'),
                            ),
                            DropdownMenuItem(
                              value: 'mexico',
                              child: Text('México 🇲🇽'),
                            ),
                            DropdownMenuItem(
                              value: 'usa',
                              child: Text('Estados Unidos 🇺🇸'),
                            ),
                            DropdownMenuItem(
                              value: 'custom',
                              child: Text('Otro / Personalizado 🌐'),
                            ),
                          ],
                          onChanged: _onCountryChanged,
                        ),
                        const SizedBox(height: 16),

                        // Idioma
                        const Text(
                          'Idioma de la Aplicación',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          items: const [
                            DropdownMenuItem(
                              value: 'es',
                              child: Text('Español'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLanguage = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Divisa
                        const Text(
                          'Divisa / Moneda de Trabajo',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCountry == 'custom'
                              ? 'CUSTOM'
                              : _selectedCurrency,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          items: [
                            const DropdownMenuItem(
                              value: 'CLP',
                              child: Text('Peso Chileno (CLP)'),
                            ),
                            const DropdownMenuItem(
                              value: 'ARS',
                              child: Text('Peso Argentino (ARS)'),
                            ),
                            const DropdownMenuItem(
                              value: 'MXN',
                              child: Text('Peso Mexicano (MXN)'),
                            ),
                            const DropdownMenuItem(
                              value: 'USD',
                              child: Text('Dólar (USD)'),
                            ),
                            const DropdownMenuItem(
                              value: 'EUR',
                              child: Text('Euro (EUR)'),
                            ),
                            if (_selectedCountry == 'custom')
                              const DropdownMenuItem(
                                value: 'CUSTOM',
                                child: Text('Otro (Ingresar Código)'),
                              ),
                          ],
                          onChanged: _selectedCountry == 'custom'
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _selectedCurrency = val);
                                  }
                                },
                        ),
                        if (_selectedCountry == 'custom') ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _customCurrencyCtrl,
                            decoration: const InputDecoration(
                              labelText:
                                  'Escribe tu divisa (ej: ARS, COP, PEN)',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa el código de divisa'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Impuesto por defecto
                        const Text(
                          'IVA / Impuesto por Defecto (%)',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _taxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el impuesto por defecto';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Ingresa un porcentaje válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Costo Eléctrico por kWh
                        const Text(
                          'Costo de Electricidad por kWh',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _kwhCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el costo por kWh';
                            }
                            if (double.tryParse(value.replaceAll(',', '.')) == null) {
                              return 'Ingresa un valor numérico válido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar y Comenzar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
