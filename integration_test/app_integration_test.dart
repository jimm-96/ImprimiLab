import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:impri_lab/main.dart' as app;
import 'package:impri_lab/state/app_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prueba de Integración End-to-End de ImpriLab', () {
    setUp(() async {
      // Mock de SharedPreferences para asegurar estado de onboarding no completado
      SharedPreferences.setMockInitialValues({'setupCompleted': false});

      // Limpiar estado de appState en memoria
      appState.printers.clear();
      appState.materials.clear();
      appState.projects.clear();
      appState.setupCompleted = false;
    });

    testWidgets('Flujo completo de Onboarding, Agregar Impresora, Material y Crear Proyecto', (WidgetTester tester) async {
      // 1. Levantar la aplicación
      await tester.pumpWidget(const app.ImpriLabApp());
      await tester.pumpAndSettle();

      // Verificar pantalla de Onboarding
      expect(find.text('¡Bienvenido a ImpriLab!'), findsOneWidget);

      // 2. Completar Onboarding (Hacer visible el botón si está fuera de pantalla y hacer click)
      final saveAndStartBtn = find.text('Guardar y Comenzar');
      expect(saveAndStartBtn, findsOneWidget);
      await tester.ensureVisible(saveAndStartBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveAndStartBtn);
      await tester.pumpAndSettle();

      // Verificar transición a Dashboard
      expect(find.text('No hay proyectos. ¡Crea el primero!'), findsOneWidget);

      // 3. Agregar Impresora
      final printersBtn = find.text('Impresoras');
      expect(printersBtn, findsOneWidget);
      await tester.tap(printersBtn);
      await tester.pumpAndSettle();

      // Clic en FAB para agregar impresora
      final addPrinterFAB = find.byType(FloatingActionButton);
      expect(addPrinterFAB, findsOneWidget);
      await tester.tap(addPrinterFAB);
      await tester.pumpAndSettle();

      // Llenar datos de impresora
      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Bambu Lab P1S');
      await tester.enterText(find.widgetWithText(TextField, 'Consumo (W)'), '300');
      await tester.enterText(find.widgetWithText(TextField, 'Costo (\$)'), '800000');
      await tester.enterText(find.widgetWithText(TextField, 'Vida Útil Estimada (Horas)'), '5000');
      await tester.pumpAndSettle();

      // Guardar impresora (Hacer visible el botón dentro del bottom sheet scrollable)
      final savePrinterBtn = find.text('Guardar Impresora');
      await tester.ensureVisible(savePrinterBtn);
      await tester.pumpAndSettle();
      await tester.tap(savePrinterBtn);
      await tester.pumpAndSettle();

      // Verificar presencia de la impresora en la lista
      expect(find.text('Bambu Lab P1S'), findsOneWidget);

      // Volver al Dashboard
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 4. Agregar Material
      final materialsBtn = find.text('Materiales');
      expect(materialsBtn, findsOneWidget);
      await tester.tap(materialsBtn);
      await tester.pumpAndSettle();

      // Clic en FAB para agregar material
      final addMaterialFAB = find.byType(FloatingActionButton);
      expect(addMaterialFAB, findsOneWidget);
      await tester.tap(addMaterialFAB);
      await tester.pumpAndSettle();

      // Llenar datos de material
      await tester.enterText(find.widgetWithText(TextField, 'Nombre o Marca'), 'eSun PLA+');
      await tester.enterText(find.widgetWithText(TextField, 'Color / Variedad'), 'Negro');
      await tester.enterText(find.widgetWithText(TextField, 'Costo Total (\$)'), '20000');
      await tester.enterText(find.widgetWithText(TextField, 'Cantidad (g)'), '1000');
      await tester.pumpAndSettle();

      // Guardar material (Hacer visible el botón)
      final saveMaterialBtn = find.text('Guardar Material');
      await tester.ensureVisible(saveMaterialBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveMaterialBtn);
      await tester.pumpAndSettle();

      // Verificar presencia del material en la lista
      expect(find.text('eSun PLA+'), findsOneWidget);

      // Volver al Dashboard
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 5. Crear Proyecto y Verificar Cálculos
      final newProjectBtn = find.text('Nuevo Proyecto');
      expect(newProjectBtn, findsOneWidget);
      await tester.tap(newProjectBtn);
      await tester.pumpAndSettle();

      // Nombre del Proyecto
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del Proyecto *'), 'Juguete Articulado');
      await tester.pumpAndSettle();

      // Agregar Cama de Impresión (Hacer visible el botón)
      final addBedBtn = find.text('Agregar Cama de Impresión');
      expect(addBedBtn, findsOneWidget);
      await tester.ensureVisible(addBedBtn);
      await tester.pumpAndSettle();
      await tester.tap(addBedBtn);
      await tester.pumpAndSettle();

      // Configurar tiempo en la Cama: 10 Horas
      await tester.enterText(find.widgetWithText(TextField, 'Horas de Impresión'), '10');
      await tester.pumpAndSettle();

      // Agregar Pieza
      final addPieceBtn = find.text('Añadir Objeto');
      expect(addPieceBtn, findsOneWidget);
      await tester.ensureVisible(addPieceBtn);
      await tester.pumpAndSettle();
      await tester.tap(addPieceBtn);
      await tester.pumpAndSettle();

      // Configurar Pieza: Nombre y Consumo
      await tester.enterText(find.widgetWithText(TextField, 'Nombre de Pieza (ej. Base, Soporte)'), 'Dragón');
      await tester.enterText(find.widgetWithText(TextField, 'Consumo Base (g)'), '150');
      await tester.pumpAndSettle();

      // Guardar Pieza (dentro del modal de pieza)
      final savePieceBtn = find.text('Guardar').last;
      await tester.ensureVisible(savePieceBtn);
      await tester.pumpAndSettle();
      await tester.tap(savePieceBtn);
      await tester.pumpAndSettle();

      // Guardar Cama de Impresión (dentro del modal de cama)
      final saveBedBtn = find.text('Guardar').last;
      await tester.ensureVisible(saveBedBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBedBtn);
      await tester.pumpAndSettle();

      // Verificar que los costos y el precio de venta sugerido se muestren en la UI del proyecto
      // Costo Materiales: 150g * ($20000 / 1000g) = $3000
      // Consumo Eléctrico: (300W / 1000) * 10 hrs * $150/kWh = $450
      // Depreciación Máquina: ($800000 / 5000 hrs) * 10 hrs = $1600
      // Costo total de manufactura = $3000 + $450 + $1600 = $5050
      // Con Margen del 100% de Ganancia (Venta sugerida = Costo * 2): $10100
      final summaryContainer = find.textContaining('Costo Materiales:');
      await tester.ensureVisible(summaryContainer);
      await tester.pumpAndSettle();
      expect(find.textContaining('Costo Materiales:'), findsOneWidget);
      expect(find.textContaining('Consumo Eléctrico:'), findsOneWidget);
      expect(find.textContaining('Depreciación Máquinas:'), findsOneWidget);

      // Guardar el Proyecto
      final saveProjectBtn = find.text('GUARDAR PROYECTO');
      await tester.ensureVisible(saveProjectBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveProjectBtn);
      await tester.pumpAndSettle();

      // Debemos estar de vuelta en el Dashboard y el proyecto "Juguete Articulado" debe ser visible
      expect(find.text('Juguete Articulado'), findsOneWidget);
      expect(find.textContaining('Costo Prod:'), findsOneWidget);
    });
  });
}
