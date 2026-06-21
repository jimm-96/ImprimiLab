import 'printer.dart';
import 'material3d.dart';
import 'piece.dart';

class PrintBed {
  final String id;
  String name;
  Printer printer;
  Material3D material;
  int printHours;
  int printMinutes;
  List<Piece> pieces;

  PrintBed({
    required this.id,
    required this.name,
    required this.printer,
    required this.material,
    this.printHours = 0,
    this.printMinutes = 0,
    this.pieces = const [],
  });

  double get timeHours => printHours + (printMinutes / 60.0);

  double getMaterialCost() {
    return pieces.fold(
      0.0,
      (sum, piece) => sum + (piece.totalMaterialUsed * material.costPerUnit),
    );
  }

  double getElectricityCost(double kwhPrice) {
    return (printer.powerW / 1000) * timeHours * kwhPrice;
  }

  double getDepreciation() {
    return printer.lifespanH > 0
        ? (printer.cost / printer.lifespanH) * timeHours
        : 0.0;
  }

  double getTotalCost(double kwhPrice) {
    return getMaterialCost() + getElectricityCost(kwhPrice) + getDepreciation();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'printer': printer.toJson(),
    'material': material.toJson(),
    'printHours': printHours,
    'printMinutes': printMinutes,
    'pieces': pieces.map((p) => p.toJson()).toList(),
  };

  factory PrintBed.fromJson(Map<String, dynamic> json) {
    var piecesJson = json['pieces'] as List? ?? [];
    List<Piece> parsedPieces = piecesJson
        .map((p) => Piece.fromJson(p))
        .toList();

    return PrintBed(
      id: json['id'],
      name: json['name'],
      printer: Printer.fromJson(json['printer']),
      material: Material3D.fromJson(json['material']),
      printHours: json['printHours'] as int? ?? 0,
      printMinutes: json['printMinutes'] as int? ?? 0,
      pieces: parsedPieces,
    );
  }
}
