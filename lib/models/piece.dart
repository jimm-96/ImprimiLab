import 'slicer_config.dart';

class Piece {
  String name;
  double quantityUsed; // gramos o ml base
  bool isLossPercent; // true = porcentaje, false = gramos o ml fijos
  double lossValue;
  SlicerConfig slicerConfig;

  Piece({
    required this.name,
    required this.quantityUsed,
    this.isLossPercent = true,
    this.lossValue = 0.0,
    required this.slicerConfig,
  });

  double get lossQuantity =>
      isLossPercent ? (quantityUsed * lossValue / 100.0) : lossValue;

  double get totalMaterialUsed => quantityUsed + lossQuantity;

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantityUsed': quantityUsed,
    'isLossPercent': isLossPercent,
    'lossValue': lossValue,
    'slicerConfig': slicerConfig.toJson(),
  };

  factory Piece.fromJson(Map<String, dynamic> json) => Piece(
    name: json['name'],
    quantityUsed: (json['quantityUsed'] as num).toDouble(),
    isLossPercent: json['isLossPercent'] as bool? ?? true,
    lossValue: (json['lossValue'] as num?)?.toDouble() ?? 0.0,
    slicerConfig: SlicerConfig.fromJson(json['slicerConfig']),
  );
}
