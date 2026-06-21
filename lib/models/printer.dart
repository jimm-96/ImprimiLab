class Printer {
  final String id;
  final String name;
  final bool isResin;
  final double powerW;
  final double cost;
  final double lifespanH;
  final DateTime? purchaseDate;
  final bool isEnabled;

  Printer({
    required this.id,
    required this.name,
    required this.isResin,
    required this.powerW,
    required this.cost,
    required this.lifespanH,
    this.purchaseDate,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isResin': isResin,
    'powerW': powerW,
    'cost': cost,
    'lifespanH': lifespanH,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'isEnabled': isEnabled,
  };

  factory Printer.fromJson(Map<String, dynamic> json) => Printer(
    id: json['id'],
    name: json['name'],
    isResin: json['isResin'],
    powerW: (json['powerW'] as num).toDouble(),
    cost: (json['cost'] as num).toDouble(),
    lifespanH: (json['lifespanH'] as num).toDouble(),
    purchaseDate: json['purchaseDate'] != null
        ? DateTime.parse(json['purchaseDate'])
        : null,
    isEnabled: json['isEnabled'] as bool? ?? true,
  );
}
