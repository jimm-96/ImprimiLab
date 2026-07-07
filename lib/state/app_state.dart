import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/project.dart';
import '../models/user_profile.dart';
import '../services/localization_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  double electricityPriceKwh = 150.0; // Precio por defecto del kWh

  List<Printer> printers = [];
  List<Material3D> materials = [];
  List<Project> projects = [];
  UserProfile? currentUser;

  // Ajustes globales de internacionalización
  bool setupCompleted = false;
  bool tutorialCompleted = false;
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
      tutorialCompleted = prefs.getBool('tutorialCompleted') ?? false;
      country = prefs.getString('country') ?? "Chile";
      language = prefs.getString('language') ?? "es";
      currency = prefs.getString('currency') ?? "CLP";
      defaultTaxRate = prefs.getDouble('defaultTaxRate') ?? 19.0;
      defaultCalibrationWeight = prefs.getDouble('defaultCalibrationWeight') ?? 10.0;

      electricityPriceKwh =
          prefs.getDouble('electricityPriceKwh') ??
          (currency == 'CLP' ? 150.0 : (currency == 'MXN' ? 2.5 : 0.15));

      final db = DatabaseService.instance;
      final loggedInUserId = prefs.getString('logged_in_user_id');
      if (loggedInUserId != null) {
        currentUser = await db.getProfileById(loggedInUserId);
      }

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
      await prefs.setBool('tutorialCompleted', tutorialCompleted);
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

  Future<void> markTutorialCompleted() async {
    tutorialCompleted = true;
    await saveState();
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    tutorialCompleted = false;
    await saveState();
    notifyListeners();
  }

  // Métodos de gestión de impresoras con SQLite
  void addPrinter(Printer printer) async {
    printers.add(printer);
    notifyListeners();
    try {
      await DatabaseService.instance.insertPrinter(printer);
    } catch (e) {
      debugPrint("Error al guardar impresora en DB: $e");
    }
  }

  void deletePrinter(String id) async {
    printers.removeWhere((p) => p.id == id);
    notifyListeners();
    try {
      await DatabaseService.instance.deletePrinter(id);
    } catch (e) {
      debugPrint("Error al eliminar impresora de DB: $e");
    }
  }

  void updatePrinter(Printer printer) async {
    final idx = printers.indexWhere((p) => p.id == printer.id);
    if (idx != -1) {
      printers[idx] = printer;
      notifyListeners();
      try {
        await DatabaseService.instance.updatePrinter(printer);
      } catch (e) {
        debugPrint("Error al actualizar impresora en DB: $e");
      }
    }
  }

  // Métodos de gestión de materiales con SQLite
  void addMaterial(Material3D material) async {
    materials.add(material);
    notifyListeners();
    try {
      await DatabaseService.instance.insertMaterial(material);
    } catch (e) {
      debugPrint("Error al guardar material en DB: $e");
    }
  }

  void deleteMaterial(String id) async {
    materials.removeWhere((m) => m.id == id);
    notifyListeners();
    try {
      await DatabaseService.instance.deleteMaterial(id);
    } catch (e) {
      debugPrint("Error al eliminar material de DB: $e");
    }
  }

  void updateMaterial(Material3D material) async {
    final idx = materials.indexWhere((m) => m.id == material.id);
    if (idx != -1) {
      materials[idx] = material;
      notifyListeners();
      try {
        await DatabaseService.instance.updateMaterial(material);
      } catch (e) {
        debugPrint("Error al actualizar material en DB: $e");
      }

      // Alerta de stock bajo
      if (NotificationService.instance.isLowMaterialActive &&
          material.remainingQuantity <= NotificationService.instance.lowMaterialThreshold) {
        final unit = material.isResin ? 'ml' : 'g';
        NotificationService.instance.showInstantNotification(
          id: material.id.hashCode,
          title: '⚠️ ¡Material Bajo en Stock!',
          body: 'Queda poco del material: ${material.name} (${material.color}). Stock restante: ${material.remainingQuantity.round()}$unit.',
        );
      }
    }
  }

  void updateMaterialRemaining(String id, double newRemaining) async {
    final idx = materials.indexWhere((m) => m.id == id);
    if (idx != -1) {
      materials[idx].remainingQuantity = newRemaining;
      notifyListeners();
      try {
        await DatabaseService.instance.updateMaterial(materials[idx]);
      } catch (e) {
        debugPrint("Error al actualizar stock de material en DB: $e");
      }

      // Alerta de stock bajo
      final material = materials[idx];
      if (NotificationService.instance.isLowMaterialActive &&
          newRemaining <= NotificationService.instance.lowMaterialThreshold) {
        final unit = material.isResin ? 'ml' : 'g';
        NotificationService.instance.showInstantNotification(
          id: id.hashCode,
          title: '⚠️ ¡Material Bajo en Stock!',
          body: 'Queda poco del material: ${material.name} (${material.color}). Stock restante: ${newRemaining.round()}$unit.',
        );
      }
    }
  }

  // Métodos de gestión de proyectos y deducción de stock con SQLite
  Future<void> addProject(Project project) async {
    projects.add(project);
    deductMaterialForProject(project);
    notifyListeners();
    try {
      await DatabaseService.instance.insertProject(project);
      // Guardar cambios de stock en base de datos
      for (var bed in project.printBeds) {
        final matIdx = materials.indexWhere((m) => m.id == bed.material.id);
        if (matIdx != -1) {
          await DatabaseService.instance.updateMaterial(materials[matIdx]);
        }
      }
    } catch (e) {
      debugPrint("Error al guardar proyecto en DB: $e");
    }
  }

  Future<void> deleteProject(Project project) async {
    projects.removeWhere((p) => p.id == project.id);
    refundMaterialForProject(project);
    notifyListeners();
    try {
      await DatabaseService.instance.deleteProject(project.id);
      // Guardar cambios de stock en base de datos
      for (var bed in project.printBeds) {
        final matIdx = materials.indexWhere((m) => m.id == bed.material.id);
        if (matIdx != -1) {
          await DatabaseService.instance.updateMaterial(materials[matIdx]);
        }
      }
    } catch (e) {
      debugPrint("Error al eliminar proyecto de DB: $e");
    }
  }

  Future<void> updateProject() async {
    notifyListeners();
    try {
      // Si hay cambios locales sueltos, guardarlos todos en BD
      for (var p in projects) {
        await DatabaseService.instance.updateProject(p);
      }
    } catch (e) {
      debugPrint("Error al actualizar proyectos en DB: $e");
    }
  }

  Future<void> updateProjectState(Project updatedProject) async {
    final idx = projects.indexWhere((p) => p.id == updatedProject.id);
    if (idx != -1) {
      final oldProject = projects[idx];
      refundMaterialForProject(oldProject);
      deductMaterialForProject(updatedProject);
      projects[idx] = updatedProject;
      notifyListeners();

      try {
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
      } catch (e) {
        debugPrint("Error al actualizar estado del proyecto en DB: $e");
      }
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

        // Alerta de stock bajo
        final material = materials[materialIdx];
        if (NotificationService.instance.isLowMaterialActive &&
            material.remainingQuantity <= NotificationService.instance.lowMaterialThreshold) {
          final unit = material.isResin ? 'ml' : 'g';
          NotificationService.instance.showInstantNotification(
            id: material.id.hashCode,
            title: '⚠️ ¡Material Bajo en Stock!',
            body: 'Queda poco del material: ${material.name} (${material.color}). Stock restante: ${material.remainingQuantity.round()}$unit.',
          );
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

  // --- Session & User Profile Operations ---

  Future<bool> registerUser(String username, String password, String name, String email) async {
    final existing = await DatabaseService.instance.getProfileByUsername(username);
    if (existing != null) {
      return false; // username already taken
    }

    final String passwordHash = _hashPassword(password);
    final newUser = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      passwordHash: passwordHash,
      name: name,
      email: email,
    );

    await DatabaseService.instance.insertProfile(newUser);
    return true;
  }

  Future<bool> loginUser(String username, String password) async {
    final profile = await DatabaseService.instance.getProfileByUsername(username);
    if (profile == null) return false;

    if (profile.passwordHash != _hashPassword(password)) {
      return false; // invalid password
    }

    currentUser = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_in_user_id', profile.id);
    notifyListeners();
    return true;
  }

  Future<void> updateUserProfile(UserProfile updated) async {
    currentUser = updated;
    await DatabaseService.instance.updateProfile(updated);
    notifyListeners();
  }

  Future<void> logoutUser() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    notifyListeners();
  }

  String _hashPassword(String password) {
    return base64.encode(utf8.encode(password));
  }
}

// Instancia global
final appState = AppState();
