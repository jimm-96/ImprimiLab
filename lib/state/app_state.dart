import 'package:flutter/material.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/project.dart';

class AppState extends ChangeNotifier {
  double electricityPriceKwh =
      150.0; // Precio por defecto del kWh en pesos chilenos

  // Datos semilla pre-cargados para pruebas inmediatas
  List<Printer> printers = [
    Printer(
      id: 'p1',
      name: 'Halot Mage S 14K',
      isResin: true,
      powerW: 100,
      cost: 450000,
      lifespanH: 2000,
      purchaseDate: DateTime(2023, 10, 1),
    ),
    Printer(
      id: 'p2',
      name: 'BambuLab A1',
      isResin: false,
      powerW: 350,
      cost: 300000,
      lifespanH: 5000,
      purchaseDate: DateTime(2024, 1, 15),
    ),
  ];

  List<Material3D> materials = [
    Material3D(
      id: 'm1',
      name: 'Anycubic Basic',
      color: 'Negra',
      isResin: true,
      cost: 30000,
      totalQuantity: 1000,
      openDate: DateTime(2024, 4, 1),
    ),
    Material3D(
      id: 'm2',
      name: 'eSun PLA+',
      color: 'Gris',
      isResin: false,
      cost: 18000,
      totalQuantity: 1000,
      openDate: DateTime.now(),
    ),
  ];

  List<Project> projects = [];

  void addProject(Project project) {
    projects.add(project);
    notifyListeners();
  }

  void addPrinter(Printer printer) {
    printers.add(printer);
    notifyListeners();
  }

  void addMaterial(Material3D material) {
    materials.add(material);
    notifyListeners();
  }

  void updateProject() {
    notifyListeners();
  }
}

// Instancia global simple para el MVP
final appState = AppState();
