import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:impri_lab/state/app_state.dart';
import 'package:impri_lab/models/printer.dart';
import 'package:impri_lab/models/material3d.dart';
import 'package:impri_lab/models/piece.dart';
import 'package:impri_lab/models/print_bed.dart';
import 'package:impri_lab/models/project.dart';
import 'package:impri_lab/models/slicer_config.dart';

void main() {
  // Inicializar SharedPreferences mockeado
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pruebas unitarias de AppState - Ajustes y Configuración', () {
    test('updateSettings actualiza las variables de estado correctamente', () {
      final state = AppState();
      bool listenerNotified = false;

      state.addListener(() {
        listenerNotified = true;
      });

      state.updateSettings(
        countryVal: 'México',
        languageVal: 'es',
        currencyVal: 'MXN',
        taxRateVal: 16.0,
        electricityPriceKwhVal: 3.5,
      );

      expect(state.country, equals('México'));
      expect(state.language, equals('es'));
      expect(state.currency, equals('MXN'));
      expect(state.defaultTaxRate, equals(16.0));
      expect(state.electricityPriceKwh, equals(3.5));
      expect(state.setupCompleted, isTrue);
      expect(listenerNotified, isTrue);
    });

    test('updateCalibrationWeight actualiza el peso de calibración correctamente', () {
      final state = AppState();
      bool listenerNotified = false;

      state.addListener(() {
        listenerNotified = true;
      });

      state.updateCalibrationWeight(15.5);

      expect(state.defaultCalibrationWeight, equals(15.5));
      expect(listenerNotified, isTrue);
    });

    test('translate y format delegan dinámicamente según idioma y divisa del estado', () {
      final state = AppState();

      // Configurar idioma inglés y divisa USD
      state.updateSettings(
        countryVal: 'USA',
        languageVal: 'en',
        currencyVal: 'USD',
        taxRateVal: 8.0,
        electricityPriceKwhVal: 0.15,
      );

      expect(state.translate('printers'), equals('Printers'));
      expect(state.format(100.50), contains('\$'));
      expect(state.format(100.50), contains('100.50'));

      // Cambiar a español y divisa CLP
      state.updateSettings(
        countryVal: 'Chile',
        languageVal: 'es',
        currencyVal: 'CLP',
        taxRateVal: 19.0,
        electricityPriceKwhVal: 150.0,
      );

      expect(state.translate('printers'), equals('Impresoras'));
      expect(state.format(1500.0), contains('1.500'));
      expect(state.format(1500.0), isNot(contains('.00')));
    });
  });

  group('Pruebas unitarias de AppState - Límites y Lógica de Stock', () {
    late AppState state;
    late Material3D material;
    late Printer printer;

    setUp(() {
      state = AppState();
      material = Material3D(
        id: 'm_test_stock',
        name: 'PLA',
        isResin: false,
        cost: 20000,
        totalQuantity: 1000.0,
        remainingQuantity: 500.0, // Stock medio
      );
      state.materials = [material];

      printer = Printer(
        id: 'p_test_stock',
        name: 'Printer',
        isResin: false,
        powerW: 100,
        cost: 100000,
        lifespanH: 1000,
      );
    });

    test('deductMaterialForProject no disminuye stock por debajo de 0', () {
      // Intentar consumir 600g teniendo solo 500g
      final piece = Piece(
        name: 'Pieza Grande',
        quantityUsed: 600,
        isLossPercent: false,
        lossValue: 0,
        slicerConfig: FdmSlicerConfig(),
      );

      final bed = PrintBed(
        id: 'bed_overuse',
        name: 'Cama',
        printer: printer,
        material: material,
        pieces: [piece],
      );

      final project = Project(
        id: 'proj_overuse',
        name: 'Proyecto Overuse',
        printBeds: [bed],
        status: 'enProceso',
      );

      state.deductMaterialForProject(project);

      // El stock debería quedar en 0, no en negativo
      expect(state.materials[0].remainingQuantity, equals(0.0));
    });

    test('refundMaterialForProject no aumenta stock por encima de totalQuantity', () {
      // Cargar stock al máximo (1000g)
      state.materials[0].remainingQuantity = 1000.0;

      // Devolver stock de una pieza de 100g
      final piece = Piece(
        name: 'Pieza',
        quantityUsed: 100,
        isLossPercent: false,
        lossValue: 0,
        slicerConfig: FdmSlicerConfig(),
      );

      final bed = PrintBed(
        id: 'bed_refund',
        name: 'Cama',
        printer: printer,
        material: material,
        pieces: [piece],
      );

      final project = Project(
        id: 'proj_refund',
        name: 'Proyecto Refund',
        printBeds: [bed],
        status: 'terminado',
      );

      state.refundMaterialForProject(project);

      // El stock no debe exceder los 1000g totales
      expect(state.materials[0].remainingQuantity, equals(1000.0));
    });
  });
}
