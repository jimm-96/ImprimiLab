import 'package:flutter/material.dart';
import '../models/print_bed.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/piece.dart';
import '../state/app_state.dart';
import 'piece_modal.dart';

class PrintBedModal extends StatefulWidget {
  final PrintBed? printBed;
  final int index;
  final Function(PrintBed) onSave;

  const PrintBedModal({
    super.key,
    this.printBed,
    required this.index,
    required this.onSave,
  });

  @override
  State<PrintBedModal> createState() => _PrintBedModalState();
}

class _PrintBedModalState extends State<PrintBedModal> {
  late TextEditingController nameCtrl;
  late TextEditingController hoursCtrl;
  late TextEditingController minutesCtrl;

  Printer? selectedPrinter;
  Material3D? selectedMaterial;
  late List<Piece> tempPieces;

  @override
  void initState() {
    super.initState();
    final bed = widget.printBed;

    nameCtrl = TextEditingController(text: bed?.name ?? 'Cama ${widget.index + 1}');
    hoursCtrl = TextEditingController(text: bed?.printHours.toString() ?? '0');
    minutesCtrl = TextEditingController(text: bed?.printMinutes.toString() ?? '0');

    if (bed != null) {
      selectedPrinter = appState.printers.firstWhere(
        (p) => p.id == bed.printer.id,
        orElse: () => appState.printers.where((p) => p.isEnabled).first,
      );
      selectedMaterial = appState.materials.firstWhere(
        (m) => m.id == bed.material.id,
        orElse: () => appState.materials.first,
      );
    } else {
      selectedPrinter = appState.printers.any((p) => p.isEnabled)
          ? appState.printers.firstWhere((p) => p.isEnabled)
          : (appState.printers.isNotEmpty ? appState.printers.first : null);

      if (selectedPrinter != null) {
        final compatibleMats = appState.materials
            .where((m) => m.isResin == selectedPrinter!.isResin)
            .toList();
        selectedMaterial = compatibleMats.isNotEmpty ? compatibleMats.first : null;
      }
    }

    tempPieces = bed != null ? List.from(bed.pieces) : [];
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    hoursCtrl.dispose();
    minutesCtrl.dispose();
    super.dispose();
  }

  void _showPieceSubModal(BuildContext context, int? editIndex) {
    if (selectedPrinter == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) {
        return PieceModal(
          piece: editIndex != null ? tempPieces[editIndex] : null,
          isResin: selectedPrinter!.isResin,
          onSave: (updatedPiece) {
            setState(() {
              if (editIndex == null) {
                tempPieces.add(updatedPiece);
              } else {
                tempPieces[editIndex] = updatedPiece;
              }
            });
          },
        );
      },
    );
  }

  void _submit() {
    if (nameCtrl.text.isEmpty || selectedPrinter == null || selectedMaterial == null) {
      return;
    }

    final updatedBed = PrintBed(
      id: widget.printBed?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameCtrl.text,
      printer: selectedPrinter!,
      material: selectedMaterial!,
      printHours: int.tryParse(hoursCtrl.text) ?? 0,
      printMinutes: int.tryParse(minutesCtrl.text) ?? 0,
      pieces: List.from(tempPieces),
    );

    widget.onSave(updatedBed);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (appState.printers.isEmpty || appState.materials.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(appState.translate('no_printers_mats')),
      );
    }

    final compatiblePrinters = appState.printers.where((p) => p.isEnabled || p.id == selectedPrinter?.id).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.printBed == null
                  ? 'Agregar Cama de Impresión'
                  : 'Editar Cama de Impresión',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Cama (ej. Placa Base)',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Printer>(
              value: selectedPrinter,
              decoration: InputDecoration(
                labelText: appState.translate('printer_label'),
              ),
              dropdownColor: const Color(0xFF1E293B),
              items: compatiblePrinters
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedPrinter = v;
                  if (selectedPrinter != null) {
                    final compatibleMats = appState.materials
                        .where((m) => m.isResin == selectedPrinter!.isResin)
                        .toList();
                    if (selectedMaterial != null &&
                        !compatibleMats.any((m) => m.id == selectedMaterial!.id)) {
                      selectedMaterial = compatibleMats.isNotEmpty ? compatibleMats.first : null;
                    } else if (selectedMaterial == null && compatibleMats.isNotEmpty) {
                      selectedMaterial = compatibleMats.first;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Material3D>(
              value: selectedMaterial,
              decoration: InputDecoration(
                labelText: appState.translate('material_label'),
              ),
              dropdownColor: const Color(0xFF1E293B),
              items: appState.materials
                  .where((m) => selectedPrinter == null ? true : m.isResin == selectedPrinter!.isResin)
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.name} (${m.color})'),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => selectedMaterial = v);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: appState.translate('print_hours'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: minutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: appState.translate('print_minutes'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Objetos / Piezas en esta Cama:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showPieceSubModal(context, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir Objeto'),
                ),
              ],
            ),
            if (tempPieces.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No hay piezas en esta cama de impresión.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ...tempPieces.asMap().entries.map((entry) {
              final pIdx = entry.key;
              final p = entry.value;
              final unit = (selectedPrinter?.isResin ?? false) ? 'ml' : 'g';
              return Card(
                color: const Color(0xFF334155),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Consumo: ${p.totalMaterialUsed.round()}$unit | Perfil: ${p.slicerConfig.profileName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.cyanAccent,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showPieceSubModal(context, pIdx),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            tempPieces.removeAt(pIdx);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    appState.translate('cancel'),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(appState.translate('save')),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
