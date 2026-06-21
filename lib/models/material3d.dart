class Material3D {
  final String id;
  final String name;
  final String color;
  final bool isResin;
  final double cost;
  final double totalQuantity; // en gramos o ml
  double remainingQuantity; // en gramos o ml
  final DateTime? purchaseDate;
  final DateTime? openDate;

  Material3D({
    required this.id,
    required this.name,
    this.color = "Desconocido",
    required this.isResin,
    required this.cost,
    required this.totalQuantity,
    double? remainingQuantity,
    this.purchaseDate,
    this.openDate,
  }) : remainingQuantity = remainingQuantity ?? totalQuantity;

  double get costPerUnit => totalQuantity > 0 ? cost / totalQuantity : 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'isResin': isResin,
    'cost': cost,
    'totalQuantity': totalQuantity,
    'remainingQuantity': remainingQuantity,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'openDate': openDate?.toIso8601String(),
  };

  factory Material3D.fromJson(Map<String, dynamic> json) => Material3D(
    id: json['id'],
    name: json['name'],
    color: json['color'] ?? "Desconocido",
    isResin: json['isResin'],
    cost: (json['cost'] as num).toDouble(),
    totalQuantity: (json['totalQuantity'] as num).toDouble(),
    remainingQuantity:
        (json['remainingQuantity'] as num?)?.toDouble() ??
        (json['totalQuantity'] as num).toDouble(),
    purchaseDate: json['purchaseDate'] != null
        ? DateTime.parse(json['purchaseDate'])
        : null,
    openDate: json['openDate'] != null
        ? DateTime.parse(json['openDate'])
        : null,
  );
}
