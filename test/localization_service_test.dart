import 'package:flutter_test/flutter_test.dart';
import 'package:impri_lab/services/localization_service.dart';

void main() {
  group('Pruebas de LocalizationService - Traducciones', () {
    test('Traducción correcta de claves existentes en español e inglés', () {
      expect(LocalizationService.translate('es', 'app_title'), equals('ImpriLab'));
      expect(LocalizationService.translate('en', 'app_title'), equals('ImpriLab'));

      expect(LocalizationService.translate('es', 'printers'), equals('Impresoras'));
      expect(LocalizationService.translate('en', 'printers'), equals('Printers'));

      expect(LocalizationService.translate('es', 'urgency_red'), equals('Urgente'));
      expect(LocalizationService.translate('en', 'urgency_red'), equals('Urgent'));
    });

    test('Fallback a español si el idioma no está soportado', () {
      // Idioma 'fr' no soportado, debería comportarse como 'es'
      expect(LocalizationService.translate('fr', 'printers'), equals('Impresoras'));
    });

    test('Retorna la propia clave si esta no existe en el diccionario', () {
      expect(LocalizationService.translate('es', 'non_existing_key_123'), equals('non_existing_key_123'));
      expect(LocalizationService.translate('en', 'non_existing_key_123'), equals('non_existing_key_123'));
    });
  });

  group('Pruebas de LocalizationService - Formato de Moneda', () {
    test('Formato CLP (Chile): sin decimales', () {
      final formatted = LocalizationService.formatCurrency(1500.0, 'CLP');
      // Debe contener el símbolo '$'
      expect(formatted, contains('\$'));
      // No debe contener decimales '.00' o ',00'
      expect(formatted, isNot(contains('.00')));
      expect(formatted, isNot(contains(',00')));
      // Debe contener el número formateado con separadores de miles
      expect(formatted.replaceAll(RegExp(r'\s+'), ''), contains('1.500'));
    });

    test('Formato USD (Estados Unidos): con decimales', () {
      final formatted = LocalizationService.formatCurrency(1500.50, 'USD');
      expect(formatted, contains('\$'));
      expect(formatted, contains('50'));
    });

    test('Formato EUR (Europa): con símbolo € y decimales', () {
      final formatted = LocalizationService.formatCurrency(1500.75, 'EUR');
      expect(formatted, contains('€'));
      expect(formatted, contains('75'));
    });

    test('Formato MXN (México): con decimales', () {
      final formatted = LocalizationService.formatCurrency(1500.25, 'MXN');
      expect(formatted, contains('\$'));
      expect(formatted, contains('25'));
    });

    test('Formato ARS (Argentina): con decimales', () {
      final formatted = LocalizationService.formatCurrency(1500.99, 'ARS');
      expect(formatted, contains('\$'));
      expect(formatted, contains('99'));
    });

    test('Formato de divisa personalizada no registrada: usa el código como símbolo', () {
      final formatted = LocalizationService.formatCurrency(100.55, 'CAD');
      expect(formatted, contains('CAD'));
      expect(formatted, contains('55'));
    });
  });
}
