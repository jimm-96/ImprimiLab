import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/project.dart';
import '../models/print_bed.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('imprimilab.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE printers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        isResin INTEGER NOT NULL,
        powerW REAL NOT NULL,
        cost REAL NOT NULL,
        lifespanH REAL NOT NULL,
        purchaseDate TEXT,
        isEnabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE materials (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        isResin INTEGER NOT NULL,
        cost REAL NOT NULL,
        totalQuantity REAL NOT NULL,
        remainingQuantity REAL NOT NULL,
        purchaseDate TEXT,
        openDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        marginPercent REAL NOT NULL,
        notes TEXT NOT NULL,
        deliveryDate TEXT,
        deliveryTime TEXT,
        priority TEXT NOT NULL,
        hasSanding INTEGER NOT NULL,
        hasPainting INTEGER NOT NULL,
        preparationTimeMinutes INTEGER NOT NULL,
        preparationCostPerHour REAL NOT NULL,
        postProcessingTimeMinutes INTEGER NOT NULL,
        postProcessingCostPerHour REAL NOT NULL,
        includeIva INTEGER NOT NULL,
        ivaPercent REAL NOT NULL,
        status TEXT NOT NULL,
        referenceUrl TEXT NOT NULL,
        clientName TEXT NOT NULL,
        clientContact TEXT NOT NULL,
        collectionName TEXT NOT NULL,
        additionalCosts TEXT NOT NULL,
        printBeds TEXT NOT NULL
      )
    ''');
  }

  // --- Mappings ---

  Map<String, dynamic> _printerToDb(Printer printer) {
    return {
      'id': printer.id,
      'name': printer.name,
      'isResin': printer.isResin ? 1 : 0,
      'powerW': printer.powerW,
      'cost': printer.cost,
      'lifespanH': printer.lifespanH,
      'purchaseDate': printer.purchaseDate?.toIso8601String(),
      'isEnabled': printer.isEnabled ? 1 : 0,
    };
  }

  Printer _printerFromDb(Map<String, dynamic> row) {
    return Printer(
      id: row['id'] as String,
      name: row['name'] as String,
      isResin: (row['isResin'] as int) == 1,
      powerW: (row['powerW'] as num).toDouble(),
      cost: (row['cost'] as num).toDouble(),
      lifespanH: (row['lifespanH'] as num).toDouble(),
      purchaseDate: row['purchaseDate'] != null ? DateTime.parse(row['purchaseDate'] as String) : null,
      isEnabled: (row['isEnabled'] as int) == 1,
    );
  }

  Map<String, dynamic> _materialToDb(Material3D mat) {
    return {
      'id': mat.id,
      'name': mat.name,
      'color': mat.color,
      'isResin': mat.isResin ? 1 : 0,
      'cost': mat.cost,
      'totalQuantity': mat.totalQuantity,
      'remainingQuantity': mat.remainingQuantity,
      'purchaseDate': mat.purchaseDate?.toIso8601String(),
      'openDate': mat.openDate?.toIso8601String(),
    };
  }

  Material3D _materialFromDb(Map<String, dynamic> row) {
    return Material3D(
      id: row['id'] as String,
      name: row['name'] as String,
      color: row['color'] as String? ?? "Desconocido",
      isResin: (row['isResin'] as int) == 1,
      cost: (row['cost'] as num).toDouble(),
      totalQuantity: (row['totalQuantity'] as num).toDouble(),
      remainingQuantity: (row['remainingQuantity'] as num).toDouble(),
      purchaseDate: row['purchaseDate'] != null ? DateTime.parse(row['purchaseDate'] as String) : null,
      openDate: row['openDate'] != null ? DateTime.parse(row['openDate'] as String) : null,
    );
  }

  Map<String, dynamic> _projectToDb(Project proj) {
    return {
      'id': proj.id,
      'name': proj.name,
      'imagePath': proj.imagePath,
      'marginPercent': proj.marginPercent,
      'notes': proj.notes,
      'deliveryDate': proj.deliveryDate?.toIso8601String(),
      'deliveryTime': proj.deliveryTime != null
          ? json.encode({'hour': proj.deliveryTime!.hour, 'minute': proj.deliveryTime!.minute})
          : null,
      'priority': proj.priority,
      'hasSanding': proj.hasSanding ? 1 : 0,
      'hasPainting': proj.hasPainting ? 1 : 0,
      'preparationTimeMinutes': proj.preparationTimeMinutes,
      'preparationCostPerHour': proj.preparationCostPerHour,
      'postProcessingTimeMinutes': proj.postProcessingTimeMinutes,
      'postProcessingCostPerHour': proj.postProcessingCostPerHour,
      'includeIva': proj.includeIva ? 1 : 0,
      'ivaPercent': proj.ivaPercent,
      'status': proj.status,
      'referenceUrl': proj.referenceUrl,
      'clientName': proj.clientName,
      'clientContact': proj.clientContact,
      'collectionName': proj.collectionName,
      'additionalCosts': json.encode(proj.additionalCosts),
      'printBeds': json.encode(proj.printBeds.map((b) => b.toJson()).toList()),
    };
  }

  Project _projectFromDb(Map<String, dynamic> row) {
    final rawBeds = row['printBeds'] as String;
    final List<dynamic> decodedBeds = json.decode(rawBeds);
    final List<PrintBed> parsedBeds = decodedBeds.map((item) => PrintBed.fromJson(item)).toList();

    final rawAddCosts = row['additionalCosts'] as String;
    final List<dynamic> decodedAddCosts = json.decode(rawAddCosts);
    final List<Map<String, dynamic>> parsedAddCosts = decodedAddCosts
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    TimeOfDay? parsedTime;
    if (row['deliveryTime'] != null) {
      final timeMap = json.decode(row['deliveryTime'] as String) as Map<String, dynamic>;
      parsedTime = TimeOfDay(
        hour: timeMap['hour'] as int,
        minute: timeMap['minute'] as int,
      );
    }

    return Project(
      id: row['id'] as String,
      name: row['name'] as String,
      imagePath: row['imagePath'] as String? ?? "",
      printBeds: parsedBeds,
      marginPercent: (row['marginPercent'] as num).toDouble(),
      notes: row['notes'] as String? ?? "",
      deliveryDate: row['deliveryDate'] != null ? DateTime.parse(row['deliveryDate'] as String) : null,
      deliveryTime: parsedTime,
      priority: row['priority'] as String? ?? "Media",
      hasSanding: (row['hasSanding'] as int) == 1,
      hasPainting: (row['hasPainting'] as int) == 1,
      preparationTimeMinutes: row['preparationTimeMinutes'] as int? ?? 0,
      preparationCostPerHour: (row['preparationCostPerHour'] as num).toDouble(),
      postProcessingTimeMinutes: row['postProcessingTimeMinutes'] as int? ?? 0,
      postProcessingCostPerHour: (row['postProcessingCostPerHour'] as num).toDouble(),
      includeIva: (row['includeIva'] as int) == 1,
      ivaPercent: (row['ivaPercent'] as num? ?? 19.0).toDouble(),
      status: row['status'] as String? ?? "pendiente",
      referenceUrl: row['referenceUrl'] as String? ?? "",
      clientName: row['clientName'] as String? ?? "",
      clientContact: row['clientContact'] as String? ?? "",
      collectionName: row['collectionName'] as String? ?? "",
      additionalCosts: parsedAddCosts,
    );
  }

  // --- CRUD Operations ---

  // Printers
  Future<List<Printer>> getPrinters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('printers');
    return maps.map((row) => _printerFromDb(row)).toList();
  }

  Future<int> insertPrinter(Printer printer) async {
    final db = await database;
    return await db.insert(
      'printers',
      _printerToDb(printer),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePrinter(Printer printer) async {
    final db = await database;
    return await db.update(
      'printers',
      _printerToDb(printer),
      where: 'id = ?',
      whereArgs: [printer.id],
    );
  }

  Future<int> deletePrinter(String id) async {
    final db = await database;
    return await db.delete(
      'printers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Materials
  Future<List<Material3D>> getMaterials() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('materials');
    return maps.map((row) => _materialFromDb(row)).toList();
  }

  Future<int> insertMaterial(Material3D material) async {
    final db = await database;
    return await db.insert(
      'materials',
      _materialToDb(material),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateMaterial(Material3D material) async {
    final db = await database;
    return await db.update(
      'materials',
      _materialToDb(material),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<int> deleteMaterial(String id) async {
    final db = await database;
    return await db.delete(
      'materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Projects
  Future<List<Project>> getProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('projects');
    return maps.map((row) => _projectFromDb(row)).toList();
  }

  Future<int> insertProject(Project project) async {
    final db = await database;
    return await db.insert(
      'projects',
      _projectToDb(project),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateProject(Project project) async {
    final db = await database;
    return await db.update(
      'projects',
      _projectToDb(project),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(String id) async {
    final db = await database;
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
