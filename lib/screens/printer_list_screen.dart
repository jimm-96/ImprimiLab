import 'package:flutter/material.dart';
import '../models/printer.dart';
import '../state/app_state.dart';

class PrinterListScreen extends StatelessWidget {
  const PrinterListScreen({super.key});

  void _showAddPrinterModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final powerCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final lifeCtrl = TextEditingController();
    bool isResin = false;
    DateTime? tempPurchaseDate;

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
                      'Nueva Impresora',
                      style: TextStyle(fontSize: 20, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    SwitchListTile(
                      title: const Text('¿Es de Resina?'),
                      value: isResin,
                      onChanged: (val) => setStateModal(() => isResin = val),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: powerCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Consumo (W)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Costo (\$)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: lifeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vida Útil Estimada (Horas)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Fecha de Compra:"),
                      subtitle: Text(
                        tempPurchaseDate == null
                            ? "No seleccionada"
                            : "${tempPurchaseDate!.day}/${tempPurchaseDate!.month}/${tempPurchaseDate!.year}",
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
                            setStateModal(() => tempPurchaseDate = date);
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
                                powerCtrl.text.isEmpty ||
                                costCtrl.text.isEmpty ||
                                lifeCtrl.text.isEmpty) {
                              return;
                            }
                            try {
                              final p = Printer(
                                id: DateTime.now().toString(),
                                name: nameCtrl.text,
                                isResin: isResin,
                                powerW: double.parse(
                                  powerCtrl.text.replaceAll(',', '.'),
                                ),
                                cost: double.parse(
                                  costCtrl.text.replaceAll(',', '.'),
                                ),
                                lifespanH: double.parse(
                                  lifeCtrl.text.replaceAll(',', '.'),
                                ),
                                purchaseDate: tempPurchaseDate,
                              );
                              appState.addPrinter(p);
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
                          child: const Text('Guardar Impresora'),
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
          'Impresoras Disponibles',
          style: TextStyle(color: Colors.cyanAccent),
        ),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          if (appState.printers.isEmpty) {
            return const Center(child: Text("No hay impresoras"));
          }
          return ListView.builder(
            itemCount: appState.printers.length,
            itemBuilder: (context, index) {
              final printer = appState.printers[index];
              return ListTile(
                leading: Icon(
                  printer.isResin ? Icons.water_drop : Icons.print,
                  color: Colors.cyanAccent,
                ),
                title: Text(
                  printer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${printer.isResin ? "Resina" : "FDM"} - ${printer.powerW}W - \$${printer.cost.round()}',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPrinterModal(context),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
