import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../models/project.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _laborCtrl;
  late double _margin;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
    _imageCtrl = TextEditingController(text: widget.project.imagePath);
    _notesCtrl = TextEditingController(text: widget.project.notes);
    _laborCtrl = TextEditingController(
      text: widget.project.laborCost.toString(),
    );
    _margin = widget.project.marginPercent;
  }

  void _saveChanges() {
    widget.project.name = _nameCtrl.text;
    widget.project.imagePath = _imageCtrl.text;
    widget.project.notes = _notesCtrl.text;
    widget.project.laborCost = double.tryParse(_laborCtrl.text) ?? 0.0;
    widget.project.marginPercent = _margin;
    appState.updateProject();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Proyecto actualizado',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.cyanAccent,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = widget.project.getTotalManufacturingCost(
      appState.electricityPriceKwh,
    );
    double salePrice = widget.project.getSuggestedSalePrice(
      appState.electricityPriceKwh,
    );

    String dateStr = widget.project.deliveryDate != null
        ? "${widget.project.deliveryDate!.day}/${widget.project.deliveryDate!.month}/${widget.project.deliveryDate!.year}"
        : "Sin fecha";
    String timeStr = widget.project.deliveryTime != null
        ? widget.project.deliveryTime!.format(context)
        : "";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle de Proyecto',
          style: TextStyle(color: Colors.cyanAccent),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar Resumen',
            onPressed: () {
              String resumen = '''
📦 Proyecto: ${widget.project.name}
⚡ Prioridad: ${widget.project.priority}
🛠️ Lijado: ${widget.project.hasSanding ? 'Sí' : 'No'} | Pintura: ${widget.project.hasPainting ? 'Sí' : 'No'}
🗓️ Entrega: $dateStr $timeStr
--------------------------
💰 Costo Producción: \$${totalCost.round()}
🏷️ Precio Venta Sugerido: \$${salePrice.round()}
              ''';
              Clipboard.setData(ClipboardData(text: resumen));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Resumen copiado al portapapeles',
                    style: TextStyle(color: Colors.black),
                  ),
                  backgroundColor: Colors.cyanAccent,
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Proyecto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageCtrl,
              decoration: const InputDecoration(
                labelText: 'Ruta de la Imagen (.png/.jpg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Fecha y Hora de Entrega",
                style: TextStyle(color: Colors.cyanAccent),
              ),
              subtitle: Text("$dateStr $timeStr"),
              trailing: IconButton(
                icon: const Icon(Icons.date_range, color: Colors.orangeAccent),
                onPressed: () async {
                  DateTime? tempDate = await showDatePicker(
                    context: context,
                    initialDate: widget.project.deliveryDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (tempDate != null) {
                    if (!context.mounted) return;
                    TimeOfDay? tempTime = await showTimePicker(
                      context: context,
                      initialTime:
                          widget.project.deliveryTime ?? TimeOfDay.now(),
                    );
                    setState(() {
                      widget.project.deliveryDate = tempDate;
                      if (tempTime != null) {
                        widget.project.deliveryTime = tempTime;
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Anotaciones (Setup especial, cliente, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Piezas:',
              style: TextStyle(fontSize: 18, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 10),
            if (widget.project.pieces.isEmpty) const Text('No hay piezas'),
            ...widget.project.pieces.map(
              (p) => Card(
                color: const Color(0xFF334155),
                child: ListTile(
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${p.material.name}\nConsume: ${p.quantityUsed}g o ml | Demora: ${p.timeHours}h\nSlicer config: ${p.slicerConfig.summary}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '\$${p.getTotalCost(appState.electricityPriceKwh).round()}',
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'Ajustes Financieros:',
              style: TextStyle(fontSize: 18, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _laborCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mano de Obra (\$)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                widget.project.laborCost =
                    double.tryParse(_laborCtrl.text) ?? 0.0;
              }),
            ),
            const SizedBox(height: 20),
            Text('Margen: ${_margin.toInt()}%'),
            Slider(
              value: _margin,
              min: 0,
              max: 500,
              divisions: 50,
              activeColor: Colors.orangeAccent,
              onChanged: (val) => setState(() {
                _margin = val;
                widget.project.marginPercent = val;
              }),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Costo Producción:'),
                      SelectableText(
                        '\$${totalCost.round()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Venta Sugerida:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SelectableText(
                        '\$${salePrice.round()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _saveChanges();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.cyanAccent,
              ),
              child: const Text(
                'GUARDAR CAMBIOS Y VOLVER',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
