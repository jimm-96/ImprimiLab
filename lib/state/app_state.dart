import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/project.dart';
import '../services/localization_service.dart';

class AppState extends ChangeNotifier {
  double electricityPriceKwh = 150.0; // Precio por defecto del kWh

  List<Printer> printers = [];
  List<Material3D> materials = [];
  List<Project> projects = [];

  // Ajustes globales de internacionalización
  bool setupCompleted = false;
  String country = "Chile";
  String language = "es";
  String currency = "CLP";
  double defaultTaxRate = 19.0;
  double defaultCalibrationWeight = 10.0;

  // Datos semilla pre-cargados para primer inicio
  final List<Printer> _seedPrinters = [
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

  final List<Material3D> _seedMaterials = [
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

  Future<void> init() async {
    await loadState();
  }

  Future<void> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar ajustes globales
      setupCompleted = prefs.getBool('setupCompleted') ?? false;
      country = prefs.getString('country') ?? "Chile";
      language = prefs.getString('language') ?? "es";
      currency = prefs.getString('currency') ?? "CLP";
      defaultTaxRate = prefs.getDouble('defaultTaxRate') ?? 19.0;
      defaultCalibrationWeight = prefs.getDouble('defaultCalibrationWeight') ?? 10.0;

      electricityPriceKwh =
          prefs.getDouble('electricityPriceKwh') ??
          (currency == 'CLP' ? 150.0 : (currency == 'MXN' ? 2.5 : 0.15));

      final printersStr = prefs.getString('printers');
      if (printersStr != null) {
        final List<dynamic> decoded = json.decode(printersStr);
        printers = decoded.map((item) => Printer.fromJson(item)).toList();
      } else {
        printers = List.from(_seedPrinters);
      }

      final materialsStr = prefs.getString('materials');
      if (materialsStr != null) {
        final List<dynamic> decoded = json.decode(materialsStr);
        materials = decoded.map((item) => Material3D.fromJson(item)).toList();
      } else {
        materials = List.from(_seedMaterials);
      }

      final projectsStr = prefs.getString('projects');
      if (projectsStr != null) {
        final List<dynamic> decoded = json.decode(projectsStr);
        projects = decoded.map((item) => Project.fromJson(item)).toList();
      } else {
        projects = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error al cargar estado de SharedPreferences: $e");
      printers = List.from(_seedPrinters);
      materials = List.from(_seedMaterials);
      projects = [];
      notifyListeners();
    }
  }

  Future<void> saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar ajustes globales
      await prefs.setBool('setupCompleted', setupCompleted);
      await prefs.setString('country', country);
      await prefs.setString('language', language);
      await prefs.setString('currency', currency);
      await prefs.setDouble('defaultTaxRate', defaultTaxRate);
      await prefs.setDouble('defaultCalibrationWeight', defaultCalibrationWeight);

      await prefs.setDouble('electricityPriceKwh', electricityPriceKwh);

      final printersStr = json.encode(printers.map((p) => p.toJson()).toList());
      await prefs.setString('printers', printersStr);

      final materialsStr = json.encode(
        materials.map((m) => m.toJson()).toList(),
      );
      await prefs.setString('materials', materialsStr);

      final projectsStr = json.encode(projects.map((p) => p.toJson()).toList());
      await prefs.setString('projects', projectsStr);
    } catch (e) {
      debugPrint("Error al guardar estado en SharedPreferences: $e");
    }
  }

  // Traducción y formato dinámicos en base al idioma/divisa del estado
  String translate(String key) {
    return LocalizationService.translate(language, key);
  }

  String format(double amount) {
    return LocalizationService.formatCurrency(amount, currency);
  }

  // Guardar configuración modificada (Onboarding/Settings dialog)
  void updateSettings({
    required String countryVal,
    required String languageVal,
    required String currencyVal,
    required double taxRateVal,
    required double electricityPriceKwhVal,
  }) {
    country = countryVal;
    language = languageVal;
    currency = currencyVal;
    defaultTaxRate = taxRateVal;
    electricityPriceKwh = electricityPriceKwhVal;
    setupCompleted = true;

    saveState();
    notifyListeners();
  }

  void updateCalibrationWeight(double weight) {
    defaultCalibrationWeight = weight;
    saveState();
    notifyListeners();
  }

  // Métodos de gestión de impresoras
  void addPrinter(Printer printer) {
    printers.add(printer);
    saveState();
    notifyListeners();
  }

  void deletePrinter(String id) {
    printers.removeWhere((p) => p.id == id);
    saveState();
    notifyListeners();
  }

  void updatePrinter(Printer printer) {
    final idx = printers.indexWhere((p) => p.id == printer.id);
    if (idx != -1) {
      printers[idx] = printer;
      saveState();
      notifyListeners();
    }
  }

  // Métodos de gestión de materiales
  void addMaterial(Material3D material) {
    materials.add(material);
    saveState();
    notifyListeners();
  }

  void deleteMaterial(String id) {
    materials.removeWhere((m) => m.id == id);
    saveState();
    notifyListeners();
  }

  void updateMaterial(Material3D material) {
    final idx = materials.indexWhere((m) => m.id == material.id);
    if (idx != -1) {
      materials[idx] = material;
      saveState();
      notifyListeners();
    }
  }

  void updateMaterialRemaining(String id, double newRemaining) {
    final idx = materials.indexWhere((m) => m.id == id);
    if (idx != -1) {
      materials[idx].remainingQuantity = newRemaining;
      saveState();
      notifyListeners();
    }
  }

  // Métodos de gestión de proyectos y deducción de stock
  void addProject(Project project) {
    projects.add(project);
    deductMaterialForProject(project);
    saveState();
    notifyListeners();
  }

  void deleteProject(Project project) {
    projects.removeWhere((p) => p.id == project.id);
    refundMaterialForProject(project);
    saveState();
    notifyListeners();
  }

  void updateProject() {
    saveState();
    notifyListeners();
  }

  void updateProjectState(Project updatedProject) {
    final idx = projects.indexWhere((p) => p.id == updatedProject.id);
    if (idx != -1) {
      final oldProject = projects[idx];
      refundMaterialForProject(oldProject);
      deductMaterialForProject(updatedProject);
      projects[idx] = updatedProject;
      saveState();
      notifyListeners();
    }
  }

  bool _shouldDeductMaterial(String status) {
    return status == 'enProceso' ||
        status == 'terminado' ||
        status == 'propio' ||
        status == 'independiente';
  }

  // Deducción y devolución de inventario
  void deductMaterialForProject(Project project) {
    if (!_shouldDeductMaterial(project.status)) return;
    for (var bed in project.printBeds) {
      final materialIdx = materials.indexWhere((m) => m.id == bed.material.id);
      if (materialIdx != -1) {
        for (var piece in bed.pieces) {
          materials[materialIdx].remainingQuantity -= piece.totalMaterialUsed;
        }
        if (materials[materialIdx].remainingQuantity < 0) {
          materials[materialIdx].remainingQuantity = 0;
        }
      }
    }
  }

  void refundMaterialForProject(Project project) {
    if (!_shouldDeductMaterial(project.status)) return;
    for (var bed in project.printBeds) {
      final materialIdx = materials.indexWhere((m) => m.id == bed.material.id);
      if (materialIdx != -1) {
        for (var piece in bed.pieces) {
          materials[materialIdx].remainingQuantity += piece.totalMaterialUsed;
        }
        if (materials[materialIdx].remainingQuantity >
            materials[materialIdx].totalQuantity) {
          materials[materialIdx].remainingQuantity =
              materials[materialIdx].totalQuantity;
        }
      }
    }
  }
}

// Instancia global
final appState = AppState();
