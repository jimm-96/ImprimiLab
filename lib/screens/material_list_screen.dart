import 'package:flutter/material.dart';
import '../models/material3d.dart';
import '../state/app_state.dart';

class MaterialListScreen extends StatelessWidget {
  const MaterialListScreen({super.key});

  void _showAddMaterialModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    bool isResin = false;
    DateTime? tempOpenDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nuevo Material',
                      style: TextStyle(fontSize: 20, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o Marca',
                      ),
                    ),
                    TextField(
                      controller: colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color / Variedad',
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('¿Es Resina?'),
                      value: isResin,
                      onChanged: (val) => setStateModal(() => isResin = val),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Costo Total (\$)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad (g o ml)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Fecha de Apertura:"),
                      subtitle: Text(
                        tempOpenDate == null
                            ? "No seleccionada"
                            : "${tempOpenDate!.day}/${tempOpenDate!.month}/${tempOpenDate!.year}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.cyanAccent,
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2010),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setStateModal(() => tempOpenDate = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.isEmpty ||
                                colorCtrl.text.isEmpty ||
                                costCtrl.text.isEmpty ||
                                qtyCtrl.text.isEmpty) {
                              return;
                            }
                            try {
                              final m = Material3D(
                                id: DateTime.now().toString(),
                                name: nameCtrl.text,
                                color: colorCtrl.text,
                                isResin: isResin,
                                cost: double.parse(
                                  costCtrl.text.replaceAll(',', '.'),
                                ),
                                totalQuantity: double.parse(
                                  qtyCtrl.text.replaceAll(',', '.'),
                                ),
                                openDate: tempOpenDate,
                              );
                              appState.addMaterial(m);
                              Navigator.pop(ctx);
                            } catch (e) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Formato de número inválido',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Guardar Material'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Materiales Disponibles',
          style: TextStyle(color: Colors.cyanAccent),
        ),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          if (appState.materials.isEmpty) {
            return const Center(child: Text("No hay materiales"));
          }
          return ListView.builder(
            itemCount: appState.materials.length,
            itemBuilder: (context, index) {
              final material = appState.materials[index];
              return ListTile(
                leading: const Icon(Icons.circle, color: Colors.white),
                title: Text(
                  '${material.name} - ${material.color}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${material.isResin ? "Resina" : "Filamento"} - ${material.totalQuantity.round()}g/ml - \$${material.cost.round()}',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMaterialModal(context),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
