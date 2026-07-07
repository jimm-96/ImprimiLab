import 'package:flutter/material.dart';
import '../models/printer.dart';
import '../state/app_state.dart';
import '../state/theme_state.dart';

class PrinterListScreen extends StatelessWidget {
  const PrinterListScreen({super.key});

  void _showPrinterModal(BuildContext context, {Printer? printer}) {
    final nameCtrl = TextEditingController(text: printer?.name ?? '');
    final powerCtrl = TextEditingController(
      text: printer?.powerW.toString() ?? '',
    );
    final costCtrl = TextEditingController(
      text: printer?.cost.toString() ?? '',
    );
    final lifeCtrl = TextEditingController(
      text: printer?.lifespanH.toString() ?? '',
    );
    bool isResin = printer?.isResin ?? false;
    DateTime? tempPurchaseDate = printer?.purchaseDate;

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
                    Text(
                      printer == null
                          ? appState.translate('new_printer')
                          : appState.translate('edit_printer'),
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: appState.translate('printer_name'),
                      ),
                    ),
                    SwitchListTile(
                      title: Text(appState.translate('is_resin')),
                      value: isResin,
                      onChanged: (val) => setStateModal(() => isResin = val),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: powerCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: appState.translate('printer_power'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: appState.translate('printer_cost'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: lifeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: appState.translate('printer_life'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(appState.translate('printer_purchase')),
                      subtitle: Text(
                        tempPurchaseDate == null
                            ? "No seleccionada"
                            : "${tempPurchaseDate!.day}/${tempPurchaseDate!.month}/${tempPurchaseDate!.year}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tempPurchaseDate != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  setStateModal(() => tempPurchaseDate = null),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: tempPurchaseDate ?? DateTime.now(),
                                firstDate: DateTime(2010),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setStateModal(() => tempPurchaseDate = date);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            appState.translate('cancel'),
                            style: const TextStyle(color: Colors.white54),
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
                                id:
                                    printer?.id ??
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
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
                                isEnabled: printer?.isEnabled ?? true,
                              );
                              if (printer == null) {
                                appState.addPrinter(p);
                              } else {
                                appState.updatePrinter(p);
                              }
                              Navigator.pop(ctx);
                            } catch (e) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    appState.translate('invalid_number'),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(
                            printer == null
                                ? appState.translate('save_printer')
                                : appState.translate('save'),
                          ),
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

  void _confirmDeletePrinter(
    BuildContext context,
    Printer printer, {
    bool forceDelete = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            forceDelete
                ? appState.translate('delete_printer')
                : '${appState.translate('inactivate')} / ${appState.translate('delete_printer')}',
            style: const TextStyle(color: Colors.redAccent),
          ),
          content: Text(
            forceDelete
                ? '¿Estás seguro de que deseas eliminar permanentemente a "${printer.name}"?'
                : '¿Qué deseas hacer con la impresora "${printer.name}"? Inhabilitarla la ocultará para nuevos proyectos sin alterar los existentes. Eliminarla la removerá por completo del sistema.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                appState.translate('cancel'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            if (!forceDelete)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final updated = Printer(
                    id: printer.id,
                    name: printer.name,
                    isResin: printer.isResin,
                    powerW: printer.powerW,
                    cost: printer.cost,
                    lifespanH: printer.lifespanH,
                    purchaseDate: printer.purchaseDate,
                    isEnabled: false,
                  );
                  appState.updatePrinter(updated);
                  Navigator.pop(ctx);
                },
                child: Text(appState.translate('inactivate')),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                appState.deletePrinter(printer.id);
                Navigator.pop(ctx);
              },
              child: Text(appState.translate('spool_delete')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appState.translate('printers'),
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([appState, themeState]),
        builder: (context, child) {
          if (appState.printers.isEmpty) {
            return Center(child: Text(appState.translate('no_printers')));
          }
          return ListView.builder(
            itemCount: appState.printers.length,
            itemBuilder: (context, index) {
              final printer = appState.printers[index];
              return Opacity(
                opacity: printer.isEnabled ? 1.0 : 0.5,
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: printer.isEnabled
                          ? Colors.white10
                          : Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      printer.isResin ? Icons.water_drop : Icons.print,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            printer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!printer.isEnabled) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${appState.translate('inactive')})',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${printer.isResin ? "Resina" : "FDM"} - ${printer.powerW}W - ${appState.format(printer.cost)}\nVida útil: ${printer.lifespanH.round()} hrs',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () =>
                              _showPrinterModal(context, printer: printer),
                        ),
                        IconButton(
                          icon: Icon(
                            printer.isEnabled
                                ? Icons.block
                                : Icons.check_circle_outline,
                            color: printer.isEnabled
                                ? Colors.orangeAccent
                                : Colors.greenAccent,
                          ),
                          tooltip: printer.isEnabled
                              ? appState.translate('inactivate')
                              : appState.translate('activate'),
                          onPressed: () {
                            if (printer.isEnabled) {
                              _confirmDeletePrinter(context, printer);
                            } else {
                              final updated = Printer(
                                id: printer.id,
                                name: printer.name,
                                isResin: printer.isResin,
                                powerW: printer.powerW,
                                cost: printer.cost,
                                lifespanH: printer.lifespanH,
                                purchaseDate: printer.purchaseDate,
                                isEnabled: true,
                              );
                              appState.updatePrinter(updated);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDeletePrinter(
                            context,
                            printer,
                            forceDelete: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPrinterModal(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
