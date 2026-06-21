import 'package:flutter/material.dart';
import 'print_bed.dart';
import 'piece.dart';
import 'printer.dart';
import 'material3d.dart';

class Project {
  final String id;
  String name;
  String imagePath;
  List<PrintBed> printBeds;
  double
  laborCost; // Se mantiene por compatibilidad hacia atrás o costos manuales
  double marginPercent;
  String notes;
  DateTime? deliveryDate;
  TimeOfDay? deliveryTime;
  String priority;
  bool hasSanding;
  bool hasPainting;

  // Nuevos campos para cotización avanzada y gestión de estados
  int preparationTimeMinutes;
  double preparationCostPerHour;
  int postProcessingTimeMinutes;
  double postProcessingCostPerHour;
  List<Map<String, dynamic>>
  additionalCosts; // Lista de {'name': String, 'cost': double}
  bool includeIva;
  double ivaPercent;
  String
  status; // 'pendiente', 'enProceso', 'terminado', 'propio', 'independiente'
  String referenceUrl;

  // Campos para clientes y colecciones
  String clientName;
  String clientContact;
  String collectionName;

  Project({
    required this.id,
    required this.name,
    this.imagePath = "",
    this.printBeds = const [],
    this.laborCost = 0.0,
    this.marginPercent = 100.0,
    this.notes = "",
    this.deliveryDate,
    this.deliveryTime,
    this.priority = 'Media',
    this.hasSanding = false,
    this.hasPainting = false,
    this.preparationTimeMinutes = 0,
    this.preparationCostPerHour = 0.0,
    this.postProcessingTimeMinutes = 0,
    this.postProcessingCostPerHour = 0.0,
    this.additionalCosts = const [],
    this.includeIva = false,
    this.ivaPercent = 19.0,
    this.status = 'pendiente',
    this.referenceUrl = "",
    this.clientName = "",
    this.clientContact = "",
    this.collectionName = "",
  });

  double getBedsCost(double kwhPrice) {
    return printBeds.fold(0.0, (sum, bed) => sum + bed.getTotalCost(kwhPrice));
  }

  double getLaborCost() {
    return ((preparationTimeMinutes / 60.0) * preparationCostPerHour) +
        ((postProcessingTimeMinutes / 60.0) * postProcessingCostPerHour);
  }

  double getAdditionalCostsSum() {
    return additionalCosts.fold(
      0.0,
      (sum, item) => sum + (item['cost'] as num).toDouble(),
    );
  }

  double getTotalManufacturingCost(double kwhPrice) {
    return getBedsCost(kwhPrice) +
        getLaborCost() +
        getAdditionalCostsSum() +
        laborCost;
  }

  double getSuggestedSalePrice(double kwhPrice) {
    return getTotalManufacturingCost(kwhPrice) * (1 + (marginPercent / 100));
  }

  double getIvaCost(double kwhPrice) {
    if (!includeIva) return 0.0;
    return getSuggestedSalePrice(kwhPrice) * (ivaPercent / 100.0);
  }

  double getFinalSalePrice(double kwhPrice) {
    return getSuggestedSalePrice(kwhPrice) + getIvaCost(kwhPrice);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'printBeds': printBeds.map((b) => b.toJson()).toList(),
    'laborCost': laborCost,
    'marginPercent': marginPercent,
    'notes': notes,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'deliveryTime': deliveryTime != null
        ? {'hour': deliveryTime!.hour, 'minute': deliveryTime!.minute}
        : null,
    'priority': priority,
    'hasSanding': hasSanding,
    'hasPainting': hasPainting,
    'preparationTimeMinutes': preparationTimeMinutes,
    'preparationCostPerHour': preparationCostPerHour,
    'postProcessingTimeMinutes': postProcessingTimeMinutes,
    'postProcessingCostPerHour': postProcessingCostPerHour,
    'additionalCosts': additionalCosts,
    'includeIva': includeIva,
    'ivaPercent': ivaPercent,
    'status': status,
    'referenceUrl': referenceUrl,
    'clientName': clientName,
    'clientContact': clientContact,
    'collectionName': collectionName,
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    List<PrintBed> parsedBeds = [];
    if (json['printBeds'] != null) {
      var bedsJson = json['printBeds'] as List;
      parsedBeds = bedsJson.map((b) => PrintBed.fromJson(b)).toList();
    } else if (json['pieces'] != null) {
      var piecesJson = json['pieces'] as List;
      parsedBeds = piecesJson.map((pJson) {
        final p = Piece.fromJson(pJson);
        final printer = Printer.fromJson(pJson['printer']);
        final material = Material3D.fromJson(pJson['material']);
        final printHours = pJson['printHours'] as int? ?? 0;
        final printMinutes = pJson['printMinutes'] as int? ?? 0;

        return PrintBed(
          id: DateTime.now().microsecondsSinceEpoch.toString() + p.name,
          name: p.name,
          printer: printer,
          material: material,
          printHours: printHours,
          printMinutes: printMinutes,
          pieces: [p],
        );
      }).toList();
    }

    TimeOfDay? parsedTime;
    if (json['deliveryTime'] != null) {
      var timeMap = json['deliveryTime'] as Map<String, dynamic>;
      parsedTime = TimeOfDay(
        hour: timeMap['hour'] as int,
        minute: timeMap['minute'] as int,
      );
    }

    var rawAdditionalCosts = json['additionalCosts'] as List? ?? [];
    List<Map<String, dynamic>> parsedAdditionalCosts = rawAdditionalCosts
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return Project(
      id: json['id'],
      name: json['name'],
      imagePath: json['imagePath'] ?? "",
      printBeds: parsedBeds,
      laborCost: (json['laborCost'] as num?)?.toDouble() ?? 0.0,
      marginPercent: (json['marginPercent'] as num?)?.toDouble() ?? 100.0,
      notes: json['notes'] ?? "",
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      deliveryTime: parsedTime,
      priority: json['priority'] ?? 'Media',
      hasSanding: json['hasSanding'] ?? false,
      hasPainting: json['hasPainting'] ?? false,
      preparationTimeMinutes: json['preparationTimeMinutes'] as int? ?? 0,
      preparationCostPerHour:
          (json['preparationCostPerHour'] as num?)?.toDouble() ?? 0.0,
      postProcessingTimeMinutes: json['postProcessingTimeMinutes'] as int? ?? 0,
      postProcessingCostPerHour:
          (json['postProcessingCostPerHour'] as num?)?.toDouble() ?? 0.0,
      additionalCosts: parsedAdditionalCosts,
      includeIva: json['includeIva'] as bool? ?? false,
      ivaPercent: (json['ivaPercent'] as num?)?.toDouble() ?? 19.0,
      status: json['status'] ?? 'pendiente',
      referenceUrl: json['referenceUrl'] ?? "",
      clientName: json['clientName'] ?? "",
      clientContact: json['clientContact'] ?? "",
      collectionName: json['collectionName'] ?? "",
    );
  }
}
