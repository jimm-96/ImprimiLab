import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:impri_lab/models/printer.dart';
import 'package:impri_lab/models/material3d.dart';
import 'package:impri_lab/models/slicer_config.dart';
import 'package:impri_lab/models/piece.dart';
import 'package:impri_lab/models/print_bed.dart';
import 'package:impri_lab/models/project.dart';

void main() {
  group('Pruebas de Serialización de Printer', () {
    test('Conversión a JSON y desde JSON mantiene integridad de datos', () {
      final purchaseDate = DateTime(2026, 1, 15);
      final printer = Printer(
        id: 'p_123',
        name: 'Creality Ender 3',
        isResin: false,
        powerW: 350.0,
        cost: 250000.0,
        lifespanH: 3000.0,
        purchaseDate: purchaseDate,
        isEnabled: true,
      );

      final json = printer.toJson();
      final fromJson = Printer.fromJson(json);

      expect(fromJson.id, equals(printer.id));
      expect(fromJson.name, equals(printer.name));
      expect(fromJson.isResin, equals(printer.isResin));
      expect(fromJson.powerW, equals(printer.powerW));
      expect(fromJson.cost, equals(printer.cost));
      expect(fromJson.lifespanH, equals(printer.lifespanH));
      expect(fromJson.purchaseDate, equals(purchaseDate));
      expect(fromJson.isEnabled, equals(printer.isEnabled));
    });

    test('Valores por defecto al cargar de JSON', () {
      final json = {
        'id': 'p_default',
        'name': 'Generic Printer',
        'isResin': false,
        'powerW': 200,
        'cost': 15000,
        'lifespanH': 2000,
        'purchaseDate': null,
      };

      final printer = Printer.fromJson(json);
      expect(printer.isEnabled, isTrue); // default isEnabled should be true
    });
  });

  group('Pruebas de Serialización de Material3D', () {
    test('Conversión a JSON y desde JSON mantiene integridad de datos', () {
      final purchaseDate = DateTime(2026, 2, 1);
      final openDate = DateTime(2026, 2, 5);
      final material = Material3D(
        id: 'm_456',
        name: 'Sunlu ABS',
        color: 'Azul',
        isResin: false,
        cost: 15000.0,
        totalQuantity: 1000.0,
        remainingQuantity: 850.0,
        purchaseDate: purchaseDate,
        openDate: openDate,
      );

      final json = material.toJson();
      final fromJson = Material3D.fromJson(json);

      expect(fromJson.id, equals(material.id));
      expect(fromJson.name, equals(material.name));
      expect(fromJson.color, equals(material.color));
      expect(fromJson.isResin, equals(material.isResin));
      expect(fromJson.cost, equals(material.cost));
      expect(fromJson.totalQuantity, equals(material.totalQuantity));
      expect(fromJson.remainingQuantity, equals(material.remainingQuantity));
      expect(fromJson.purchaseDate, equals(purchaseDate));
      expect(fromJson.openDate, equals(openDate));
    });

    test('Cálculo correcto de costPerUnit', () {
      final mat1 = Material3D(
        id: 'm_calc_1',
        name: 'PLA',
        isResin: false,
        cost: 20000,
        totalQuantity: 1000,
      );
      expect(mat1.costPerUnit, equals(20.0));

      final mat2 = Material3D(
        id: 'm_calc_2',
        name: 'Zero PLA',
        isResin: false,
        cost: 20000,
        totalQuantity: 0,
      );
      expect(mat2.costPerUnit, equals(0.0));
    });
  });

  group('Pruebas de Serialización de SlicerConfig', () {
    test('FdmSlicerConfig serializa y deserializa polimórficamente', () {
      final fdm = FdmSlicerConfig(
        profileName: 'Calidad Alta',
        hasSupports: true,
        supportType: 'Árbol',
        nozzleDiameter: 0.6,
        layerHeight: 0.12,
        infillPercent: 20.0,
        nozzleTemp: 220.0,
        bedTemp: 65.0,
        speed: 60.0,
      );

      final json = fdm.toJson();
      final fromJson = SlicerConfig.fromJson(json);

      expect(fromJson, isA<FdmSlicerConfig>());
      final fdmFromJson = fromJson as FdmSlicerConfig;
      expect(fdmFromJson.profileName, equals(fdm.profileName));
      expect(fdmFromJson.hasSupports, equals(fdm.hasSupports));
      expect(fdmFromJson.supportType, equals(fdm.supportType));
      expect(fdmFromJson.nozzleDiameter, equals(fdm.nozzleDiameter));
      expect(fdmFromJson.layerHeight, equals(fdm.layerHeight));
      expect(fdmFromJson.infillPercent, equals(fdm.infillPercent));
      expect(fdmFromJson.nozzleTemp, equals(fdm.nozzleTemp));
      expect(fdmFromJson.bedTemp, equals(fdm.bedTemp));
      expect(fdmFromJson.speed, equals(fdm.speed));
      expect(fdmFromJson.summary, contains('Capa: 0.12mm'));
      expect(fdmFromJson.summary, contains('Relleno: 20.0%'));
      expect(fdmFromJson.summary, contains('Soportes: Árbol'));
    });

    test('ResinSlicerConfig serializa y deserializa polimórficamente', () {
      final resin = ResinSlicerConfig(
        profileName: 'Standard Resin',
        hasSupports: false,
        supportType: '',
        layerHeight: 0.03,
        normalExposure: 1.8,
        bottomExposure: 20.0,
        bottomLayers: 5,
      );

      final json = resin.toJson();
      final fromJson = SlicerConfig.fromJson(json);

      expect(fromJson, isA<ResinSlicerConfig>());
      final resinFromJson = fromJson as ResinSlicerConfig;
      expect(resinFromJson.profileName, equals(resin.profileName));
      expect(resinFromJson.hasSupports, equals(resin.hasSupports));
      expect(resinFromJson.supportType, equals(resin.supportType));
      expect(resinFromJson.layerHeight, equals(resin.layerHeight));
      expect(resinFromJson.normalExposure, equals(resin.normalExposure));
      expect(resinFromJson.bottomExposure, equals(resin.bottomExposure));
      expect(resinFromJson.bottomLayers, equals(resin.bottomLayers));
      expect(resinFromJson.summary, contains('Capa: 0.03mm'));
      expect(resinFromJson.summary, contains('Exp: 1.8s'));
      expect(resinFromJson.summary, contains('Base: 20.0s'));
      expect(resinFromJson.summary, isNot(contains('Soportes')));
    });
  });

  group('Pruebas de Serialización de Piece', () {
    test('Conversión a JSON y desde JSON mantiene integridad de datos', () {
      final slicer = FdmSlicerConfig(profileName: 'Borrador');
      final piece = Piece(
        name: 'Lego Block',
        quantityUsed: 45.5,
        isLossPercent: false,
        lossValue: 5.0,
        slicerConfig: slicer,
      );

      final json = piece.toJson();
      final fromJson = Piece.fromJson(json);

      expect(fromJson.name, equals(piece.name));
      expect(fromJson.quantityUsed, equals(piece.quantityUsed));
      expect(fromJson.isLossPercent, equals(piece.isLossPercent));
      expect(fromJson.lossValue, equals(piece.lossValue));
      expect(fromJson.slicerConfig, isA<FdmSlicerConfig>());
      expect(fromJson.slicerConfig.profileName, equals('Borrador'));
    });
  });

  group('Pruebas de Serialización de PrintBed', () {
    test('Conversión a JSON y desde JSON mantiene integridad de datos', () {
      final printer = Printer(
        id: 'p_bed',
        name: 'Ender 3',
        isResin: false,
        powerW: 300,
        cost: 200000,
        lifespanH: 2000,
      );
      final material = Material3D(
        id: 'm_bed',
        name: 'PLA',
        isResin: false,
        cost: 18000,
        totalQuantity: 1000,
      );
      final slicer = FdmSlicerConfig();
      final piece = Piece(
        name: 'Test Piece',
        quantityUsed: 50.0,
        slicerConfig: slicer,
      );

      final bed = PrintBed(
        id: 'bed_123',
        name: 'Cama Principal',
        printer: printer,
        material: material,
        printHours: 2,
        printMinutes: 30,
        pieces: [piece],
      );

      final json = bed.toJson();
      final fromJson = PrintBed.fromJson(json);

      expect(fromJson.id, equals(bed.id));
      expect(fromJson.name, equals(bed.name));
      expect(fromJson.printer.id, equals(printer.id));
      expect(fromJson.material.id, equals(material.id));
      expect(fromJson.printHours, equals(2));
      expect(fromJson.printMinutes, equals(30));
      expect(fromJson.timeHours, equals(2.5));
      expect(fromJson.pieces.length, equals(1));
      expect(fromJson.pieces.first.name, equals('Test Piece'));
    });
  });

  group('Pruebas de Serialización de Project', () {
    test('Conversión a JSON y desde JSON mantiene integridad de datos completos', () {
      final printer = Printer(
        id: 'p_proj',
        name: 'Mage 14K',
        isResin: true,
        powerW: 100,
        cost: 400000,
        lifespanH: 2000,
      );
      final material = Material3D(
        id: 'm_proj',
        name: 'Resina Standard',
        isResin: true,
        cost: 35000,
        totalQuantity: 1000,
      );
      final slicer = ResinSlicerConfig();
      final piece = Piece(
        name: 'Estatua 3D',
        quantityUsed: 150.0,
        slicerConfig: slicer,
      );
      final bed = PrintBed(
        id: 'bed_proj',
        name: 'Cama Resina',
        printer: printer,
        material: material,
        printHours: 4,
        printMinutes: 15,
        pieces: [piece],
      );

      final deliveryDate = DateTime(2026, 6, 30);
      final deliveryTime = const TimeOfDay(hour: 15, minute: 30);

      final project = Project(
        id: 'proj_999',
        name: 'Encargo Cliente A',
        imagePath: '/path/to/image.png',
        printBeds: [bed],
        laborCost: 1500.0,
        marginPercent: 80.0,
        notes: 'Urgente entregar a tiempo.',
        deliveryDate: deliveryDate,
        deliveryTime: deliveryTime,
        priority: 'Alta',
        hasSanding: true,
        hasPainting: true,
        preparationTimeMinutes: 15,
        preparationCostPerHour: 4000.0,
        postProcessingTimeMinutes: 45,
        postProcessingCostPerHour: 5000.0,
        additionalCosts: [
          {'name': 'Tornillos M3', 'cost': 500.0},
          {'name': 'Imanes', 'cost': 1200.0},
        ],
        includeIva: true,
        ivaPercent: 19.0,
        status: 'enProceso',
        referenceUrl: 'http://example.com/model',
        clientName: 'Juan Pérez',
        clientContact: '+56912345678',
        collectionName: 'Figuras Anime',
      );

      final json = project.toJson();
      final fromJson = Project.fromJson(json);

      expect(fromJson.id, equals(project.id));
      expect(fromJson.name, equals(project.name));
      expect(fromJson.imagePath, equals(project.imagePath));
      expect(fromJson.laborCost, equals(project.laborCost));
      expect(fromJson.marginPercent, equals(project.marginPercent));
      expect(fromJson.notes, equals(project.notes));
      expect(fromJson.deliveryDate, equals(deliveryDate));
      expect(fromJson.deliveryTime?.hour, equals(deliveryTime.hour));
      expect(fromJson.deliveryTime?.minute, equals(deliveryTime.minute));
      expect(fromJson.priority, equals(project.priority));
      expect(fromJson.hasSanding, equals(project.hasSanding));
      expect(fromJson.hasPainting, equals(project.hasPainting));
      expect(fromJson.preparationTimeMinutes, equals(project.preparationTimeMinutes));
      expect(fromJson.preparationCostPerHour, equals(project.preparationCostPerHour));
      expect(fromJson.postProcessingTimeMinutes, equals(project.postProcessingTimeMinutes));
      expect(fromJson.postProcessingCostPerHour, equals(project.postProcessingCostPerHour));
      expect(fromJson.includeIva, equals(project.includeIva));
      expect(fromJson.ivaPercent, equals(project.ivaPercent));
      expect(fromJson.status, equals(project.status));
      expect(fromJson.referenceUrl, equals(project.referenceUrl));
      expect(fromJson.clientName, equals(project.clientName));
      expect(fromJson.clientContact, equals(project.clientContact));
      expect(fromJson.collectionName, equals(project.collectionName));

      // Verificar listas y colecciones internas
      expect(fromJson.printBeds.length, equals(1));
      expect(fromJson.printBeds.first.name, equals('Cama Resina'));
      expect(fromJson.additionalCosts.length, equals(2));
      expect(fromJson.additionalCosts[0]['name'], equals('Tornillos M3'));
      expect(fromJson.additionalCosts[0]['cost'], equals(500.0));
      expect(fromJson.additionalCosts[1]['name'], equals('Imanes'));
      expect(fromJson.additionalCosts[1]['cost'], equals(1200.0));
    });

    test('Deserialización compatible de proyectos antiguos usando lista de piezas directo', () {
      // Formato antiguo de base de datos donde no existía 'printBeds' sino directamente 'pieces'
      // con impresora y material inyectados por cada pieza.
      final json = {
        'id': 'legacy_1',
        'name': 'Proyecto Antiguo',
        'pieces': [
          {
            'name': 'Legacy Piece',
            'quantityUsed': 60.0,
            'isLossPercent': true,
            'lossValue': 10.0,
            'slicerConfig': {
              'type': 'fdm',
              'profileName': 'Default',
              'hasSupports': false,
              'supportType': '',
            },
            'printer': {
              'id': 'p_legacy',
              'name': 'Legacy Printer',
              'isResin': false,
              'powerW': 250,
              'cost': 150000,
              'lifespanH': 2000,
            },
            'material': {
              'id': 'm_legacy',
              'name': 'Legacy PLA',
              'isResin': false,
              'cost': 15000,
              'totalQuantity': 1000,
              'remainingQuantity': 1000,
            },
            'printHours': 3,
            'printMinutes': 30,
          }
        ],
        'laborCost': 1000.0,
        'marginPercent': 50.0,
        'status': 'enProceso',
      };

      final project = Project.fromJson(json);

      expect(project.printBeds.length, equals(1));
      final reconstructedBed = project.printBeds.first;
      expect(reconstructedBed.pieces.length, equals(1));
      expect(reconstructedBed.name, equals('Legacy Piece'));
      expect(reconstructedBed.printer.name, equals('Legacy Printer'));
      expect(reconstructedBed.material.name, equals('Legacy PLA'));
      expect(reconstructedBed.printHours, equals(3));
      expect(reconstructedBed.printMinutes, equals(30));
      expect(reconstructedBed.timeHours, equals(3.5));
    });
  });
}
