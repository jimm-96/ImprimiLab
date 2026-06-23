import 'package:flutter_test/flutter_test.dart';
import 'package:impri_lab/models/printer.dart';
import 'package:impri_lab/state/app_state.dart';
import 'package:impri_lab/models/material3d.dart';
import 'package:impri_lab/models/piece.dart';
import 'package:impri_lab/models/print_bed.dart';
import 'package:impri_lab/models/project.dart';
import 'package:impri_lab/models/slicer_config.dart';

void main() {
  group('Pruebas unitarias de PrintBed', () {
    late Printer printerFdm;
    late Material3D materialFdm;
    late SlicerConfig fdmConfig;
    late Piece piece;

    setUp(() {
      printerFdm = Printer(
        id: 'p_test',
        name: 'Bambu Lab X1C',
        isResin: false,
        powerW: 300,
        cost: 1500000,
        lifespanH: 5000,
      );

      materialFdm = Material3D(
        id: 'm_test',
        name: 'eSun PLA',
        isResin: false,
        cost: 20000,
        totalQuantity: 1000,
      );

      fdmConfig = FdmSlicerConfig(
        profileName: 'Fast',
        hasSupports: false,
        layerHeight: 0.2,
      );

      piece = Piece(
        name: 'Model 3D',
        quantityUsed: 100,
        isLossPercent: true,
        lossValue: 10.0,
        slicerConfig: fdmConfig,
      );
    });

    test('Cálculo correcto de material utilizado con merma', () {
      expect(piece.lossQuantity, equals(10.0));
      expect(piece.totalMaterialUsed, equals(110.0));
    });

    test('Cálculo correcto del costo de material en una PrintBed', () {
      final bed = PrintBed(
        id: 'bed_test',
        name: 'Cama 1',
        printer: printerFdm,
        material: materialFdm,
        printHours: 5,
        printMinutes: 0,
        pieces: [piece],
      );

      expect(bed.getMaterialCost(), equals(2200.0));
    });

    test('Cálculo correcto del costo eléctrico y depreciación', () {
      final bed = PrintBed(
        id: 'bed_test',
        name: 'Cama 1',
        printer: printerFdm,
        material: materialFdm,
        printHours: 5,
        printMinutes: 0,
        pieces: [piece],
      );

      expect(bed.getElectricityCost(150.0), equals(225.0));
      expect(bed.getDepreciation(), equals(1500.0));
      expect(bed.getTotalCost(150.0), equals(3925.0));
    });
  });

  group('Pruebas unitarias de Project (Cálculo de Precios)', () {
    late Printer printer;
    late Material3D material;
    late PrintBed bed;
    late Project project;

    setUp(() {
      printer = Printer(
        id: 'p_test',
        name: 'Bambu Lab X1C',
        isResin: false,
        powerW: 300,
        cost: 1500000,
        lifespanH: 5000,
      );

      material = Material3D(
        id: 'm_test',
        name: 'eSun PLA',
        isResin: false,
        cost: 20000,
        totalQuantity: 1000,
      );

      final piece = Piece(
        name: 'Model 3D',
        quantityUsed: 100,
        isLossPercent: false,
        lossValue: 0.0,
        slicerConfig: FdmSlicerConfig(),
      );

      bed = PrintBed(
        id: 'bed_test',
        name: 'Cama 1',
        printer: printer,
        material: material,
        printHours: 10,
        pieces: [piece],
      );

      project = Project(
        id: 'proj_test',
        name: 'Proyecto de Prueba',
        printBeds: [bed],
        marginPercent: 100.0,
        preparationTimeMinutes: 30,
        preparationCostPerHour: 5000.0,
        postProcessingTimeMinutes: 60,
        postProcessingCostPerHour: 6000.0,
        additionalCosts: [
          {'name': 'Imanes', 'cost': 1000.0}
        ],
        includeIva: true,
        ivaPercent: 19.0,
      );
    });

    test('Cálculo correcto de mano de obra y costos adicionales', () {
      expect(project.getLaborCost(), equals(8500.0));
      expect(project.getAdditionalCostsSum(), equals(1000.0));
    });

    test('Cálculo correcto de costo de producción total', () {
      expect(project.getTotalManufacturingCost(150.0), equals(14950.0));
    });

    test('Cálculo correcto de venta sugerida, IVA e importe final', () {
      expect(project.getSuggestedSalePrice(150.0), equals(29900.0));
      expect(project.getIvaCost(150.0), equals(5681.0));
      expect(project.getFinalSalePrice(150.0), equals(35581.0));
    });
  });

  group('Pruebas unitarias de AppState (Stock)', () {
    late AppState state;
    late Material3D material;
    late Printer printer;

    setUp(() {
      state = AppState();
      material = Material3D(
        id: 'm_stock',
        name: 'PLA',
        isResin: false,
        cost: 20000,
        totalQuantity: 1000,
        remainingQuantity: 1000,
      );
      state.materials = [material];

      printer = Printer(
        id: 'p_stock',
        name: 'Printer',
        isResin: false,
        powerW: 100,
        cost: 100000,
        lifespanH: 1000,
      );
    });

    test('deductMaterialForProject reduce el stock correctamente para estados válidos', () {
      final piece = Piece(
        name: 'Pieza',
        quantityUsed: 100,
        isLossPercent: false,
        lossValue: 0,
        slicerConfig: FdmSlicerConfig(),
      );

      final bed = PrintBed(
        id: 'bed_stock',
        name: 'Cama',
        printer: printer,
        material: material,
        pieces: [piece],
      );

      final project = Project(
        id: 'proj_stock',
        name: 'Proyecto En Proceso',
        printBeds: [bed],
        status: 'enProceso',
      );

      state.deductMaterialForProject(project);

      expect(state.materials[0].remainingQuantity, equals(900.0));
    });

    test('deductMaterialForProject no reduce el stock para estados no válidos (ej. borrador)', () {
      final piece = Piece(
        name: 'Pieza',
        quantityUsed: 100,
        isLossPercent: false,
        lossValue: 0,
        slicerConfig: FdmSlicerConfig(),
      );

      final bed = PrintBed(
        id: 'bed_stock',
        name: 'Cama',
        printer: printer,
        material: material,
        pieces: [piece],
      );

      final project = Project(
        id: 'proj_stock2',
        name: 'Proyecto Borrador',
        printBeds: [bed],
        status: 'borrador',
      );

      state.deductMaterialForProject(project);

      expect(state.materials[0].remainingQuantity, equals(1000.0));
    });

    test('refundMaterialForProject devuelve el stock correctamente', () {
      state.materials[0].remainingQuantity = 800.0;

      final piece = Piece(
        name: 'Pieza',
        quantityUsed: 150,
        isLossPercent: false,
        lossValue: 0,
        slicerConfig: FdmSlicerConfig(),
      );

      final bed = PrintBed(
        id: 'bed_stock',
        name: 'Cama',
        printer: printer,
        material: material,
        pieces: [piece],
      );

      final project = Project(
        id: 'proj_stock3',
        name: 'Proyecto Terminado',
        printBeds: [bed],
        status: 'terminado',
      );

      state.refundMaterialForProject(project);

      expect(state.materials[0].remainingQuantity, equals(950.0));
    });
  });
}
