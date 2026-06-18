import 'printer.dart';
import 'material3d.dart';
import 'slicer_config.dart';

class Piece {
  final String name;
  final Printer printer;
  final Material3D material;
  final double quantityUsed; // gramos o ml
  final double timeHours;
  final SlicerConfig slicerConfig;

  Piece({
    required this.name,
    required this.printer,
    required this.material,
    required this.quantityUsed,
    required this.timeHours,
    required this.slicerConfig,
  });

  double calculateMaterialCost() => quantityUsed * material.costPerUnit;
  double calculateElectricityCost(double kwhPrice) =>
      (printer.powerW / 1000) * timeHours * kwhPrice;
  double calculateDepreciation() => printer.lifespanH > 0
      ? (printer.cost / printer.lifespanH) * timeHours
      : 0.0;

  double getTotalCost(double kwhPrice) =>
      calculateMaterialCost() +
      calculateElectricityCost(kwhPrice) +
      calculateDepreciation();
}
