import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/project.dart';
import '../services/localization_service.dart';
import '../services/database_service.dart';

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

      final db = DatabaseService.instance;
      final dbPrinters = await db.getPrinters();
      final dbMaterials = await db.getMaterials();
      final dbProjects = await db.getProjects();

      if (dbPrinters.isEmpty && dbMaterials.isEmpty && dbProjects.isEmpty) {
        // La base de datos está vacía. Migrar desde SharedPreferences o cargar semillas
        final printersStr = prefs.getString('printers');
        if (printersStr != null) {
          final List<dynamic> decoded = json.decode(printersStr);
          printers = decoded.map((item) => Printer.fromJson(item)).toList();
          for (var p in printers) {
            await db.insertPrinter(p);
          }
        } else {
          printers = List.from(_seedPrinters);
          for (var p in printers) {
            await db.insertPrinter(p);
          }
        }

        final materialsStr = prefs.getString('materials');
        if (materialsStr != null) {
          final List<dynamic> decoded = json.decode(materialsStr);
          materials = decoded.map((item) => Material3D.fromJson(item)).toList();
          for (var m in materials) {
            await db.insertMaterial(m);
          }
        } else {
          materials = List.from(_seedMaterials);
          for (var m in materials) {
            await db.insertMaterial(m);
          }
        }

        final projectsStr = prefs.getString('projects');
        if (projectsStr != null) {
          final List<dynamic> decoded = json.decode(projectsStr);
          projects = decoded.map((item) => Project.fromJson(item)).toList();
          for (var p in projects) {
            await db.insertProject(p);
          }
        } else {
          projects = [];
        }
      } else {
        // Cargar normalmente de SQLite
        printers = dbPrinters;
        materials = dbMaterials;
        projects = dbProjects;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error al cargar estado: $e");
      printers = List.from(_seedPrinters);
      materials = List.from(_seedMaterials);
      projects = [];
      notifyListeners();
    }
  }

  Future<void> saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar ajustes globales solamente en SharedPreferences
      await prefs.setBool('setupCompleted', setupCompleted);
      await prefs.setString('country', country);
      await prefs.setString('language', language);
      await prefs.setString('currency', currency);
      await prefs.setDouble('defaultTaxRate', defaultTaxRate);
      await prefs.setDouble('defaultCalibrationWeight', defaultCalibrationWeight);
      await prefs.setDouble('electricityPriceKwh', electricityPriceKwh);
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

  // Métodos de gestión de impresoras con SQLite
  void addPrinter(Printer printer) async {
    printers.add(printer);
    await DatabaseService.instance.insertPrinter(printer);
    notifyListeners();
  }

  void deletePrinter(String id) async {
    printers.removeWhere((p) => p.id == id);
    await DatabaseService.instance.deletePrinter(id);
    notifyListeners();
  }

  void updatePrinter(Printer printer) async {
    final idx = printers.indexWhere((p) => p.id == printer.id);
    if (idx != -1) {
      printers[idx] = printer;
      await DatabaseService.instance.updatePrinter(printer);
      notifyListeners();
    }
  }

  // Métodos de gestión de materiales con SQLite
  void addMaterial(Material3D material) async {
    materials.add(material);
    await DatabaseService.instance.insertMaterial(material);
    notifyListeners();
  }

  void deleteMaterial(String id) async {
    materials.removeWhere((m) => m.id == id);
    await DatabaseService.instance.deleteMaterial(id);
    notifyListeners();
  }

  void updateMaterial(Material3D material) async {
    final idx = materials.indexWhere((m) => m.id == material.id);
    if (idx != -1) {
      materials[idx] = material;
      await DatabaseService.instance.updateMaterial(material);
      notifyListeners();
    }
  }

  void updateMaterialRemaining(String id, double newRemaining) async {
    final idx = materials.indexWhere((m) => m.id == id);
    if (idx != -1) {
      materials[idx].remainingQuantity = newRemaining;
      await DatabaseService.instance.updateMaterial(materials[idx]);
      notifyListeners();
    }
  }

  // Métodos de gestión de proyectos y deducción de stock con SQLite
  void addProject(Project project) async {
    projects.add(project);
    deductMaterialForProject(project);
    await DatabaseService.instance.insertProject(project);
    // Guardar cambios de stock en base de datos
    for (var bed in project.printBeds) {
      final matIdx = materials.indexWhere((m) => m.id == bed.material.id);
      if (matIdx != -1) {
        await DatabaseService.instance.updateMaterial(materials[matIdx]);
      }
    }
    notifyListeners();
  }

  void deleteProject(Project project) async {
    projects.removeWhere((p) => p.id == project.id);
    refundMaterialForProject(project);
    await DatabaseService.instance.deleteProject(project.id);
    // Guardar cambios de stock en base de datos
    for (var bed in project.printBeds) {
      final matIdx = materials.indexWhere((m) => m.id == bed.material.id);
      if (matIdx != -1) {
        await DatabaseService.instance.updateMaterial(materials[matIdx]);
      }
    }
    notifyListeners();
  }

  void updateProject() async {
    // Si hay cambios locales sueltos, guardarlos todos en BD
    for (var p in projects) {
      await DatabaseService.instance.updateProject(p);
    }
    notifyListeners();
  }

  void updateProjectState(Project updatedProject) async {
    final idx = projects.indexWhere((p) => p.id == updatedProject.id);
    if (idx != -1) {
      final oldProject = projects[idx];
      refundMaterialForProject(oldProject);
      deductMaterialForProject(updatedProject);
      projects[idx] = updatedProject;

      await DatabaseService.instance.updateProject(updatedProject);
      // Actualizar materiales cuyo stock pudo haber cambiado
      final materialIdsToUpdate = <String>{};
      for (var bed in oldProject.printBeds) {
        materialIdsToUpdate.add(bed.material.id);
      }
      for (var bed in updatedProject.printBeds) {
        materialIdsToUpdate.add(bed.material.id);
      }

      for (var matId in materialIdsToUpdate) {
        final matIdx = materials.indexWhere((m) => m.id == matId);
        if (matIdx != -1) {
          await DatabaseService.instance.updateMaterial(materials[matIdx]);
        }
      }
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
