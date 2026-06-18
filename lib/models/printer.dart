class Printer {
  final String id;
  final String name;
  final bool isResin;
  final double powerW;
  final double cost;
  final double lifespanH;
  final DateTime? purchaseDate;

  Printer({
    required this.id,
    required this.name,
    required this.isResin,
    required this.powerW,
    required this.cost,
    required this.lifespanH,
    this.purchaseDate,
  });
}
