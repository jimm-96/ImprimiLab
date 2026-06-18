import 'package:flutter/material.dart';
import 'piece.dart';

class Project {
  final String id;
  String name;
  String imagePath;
  List<Piece> pieces;
  double laborCost;
  double marginPercent;
  String notes;
  DateTime? deliveryDate;
  TimeOfDay? deliveryTime;
  String priority;
  bool hasSanding;
  bool hasPainting;

  Project({
    required this.id,
    required this.name,
    this.imagePath = "",
    this.pieces = const [],
    this.laborCost = 0.0,
    this.marginPercent = 100.0,
    this.notes = "",
    this.deliveryDate,
    this.deliveryTime,
    this.priority = 'Media',
    this.hasSanding = false,
    this.hasPainting = false,
  });

  double getTotalManufacturingCost(double kwhPrice) {
    double total = pieces.fold(
      0,
      (sum, piece) => sum + piece.getTotalCost(kwhPrice),
    );
    return total + laborCost;
  }

  double getSuggestedSalePrice(double kwhPrice) {
    return getTotalManufacturingCost(kwhPrice) * (1 + (marginPercent / 100));
  }
}
