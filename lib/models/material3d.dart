class Material3D {
  final String id;
  final String name;
  final String color;
  final bool isResin;
  final double cost;
  final double totalQuantity; // en gramos o ml
  final DateTime? openDate;

  Material3D({
    required this.id,
    required this.name,
    this.color = "Desconocido",
    required this.isResin,
    required this.cost,
    required this.totalQuantity,
    this.openDate,
  });

  double get costPerUnit => totalQuantity > 0 ? cost / totalQuantity : 0.0;
}
