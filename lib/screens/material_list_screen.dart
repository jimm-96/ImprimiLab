import 'package:flutter/material.dart';
import '../models/material3d.dart';
import '../state/app_state.dart';

class MaterialListScreen extends StatelessWidget {
  const MaterialListScreen({super.key});

  void _showMaterialModal(BuildContext context, {Material3D? material}) {
    final nameCtrl = TextEditingController(text: material?.name ?? '');
    final colorCtrl = TextEditingController(text: material?.color ?? '');
    final costCtrl = TextEditingController(
      text: material?.cost.toString() ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: material?.totalQuantity.toString() ?? '',
    );
    bool isResin = material?.isResin ?? false;
    DateTime? tempPurchaseDate = material?.purchaseDate;
    DateTime? tempOpenDate = material?.openDate;

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
                      material == null
                          ? appState.translate('new_material')
                          : appState.translate('edit_material'),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: appState.translate('material_name'),
                      ),
                    ),
                    TextField(
                      controller: colorCtrl,
                      decoration: InputDecoration(
                        labelText: appState.translate('material_color'),
                      ),
                    ),
                    SwitchListTile(
                      title: Text(appState.translate('is_resin_mat')),
                      value: isResin,
                      onChanged: (val) => setStateModal(() => isResin = val),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: appState.translate('material_cost'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isResin
                                  ? '${appState.translate('material_qty')} (ml)'
                                  : '${appState.translate('material_qty')} (g)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(appState.translate('material_purchase')),
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
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Colors.cyanAccent,
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(appState.translate('material_open')),
                      subtitle: Text(
                        tempOpenDate == null
                            ? "No seleccionada"
                            : "${tempOpenDate!.day}/${tempOpenDate!.month}/${tempOpenDate!.year}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tempOpenDate != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  setStateModal(() => tempOpenDate = null),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Colors.cyanAccent,
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: tempOpenDate ?? DateTime.now(),
                                firstDate: DateTime(2010),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setStateModal(() => tempOpenDate = date);
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
                                colorCtrl.text.isEmpty ||
                                costCtrl.text.isEmpty ||
                                qtyCtrl.text.isEmpty) {
                              return;
                            }
                            try {
                              final double qtyVal = double.parse(
                                qtyCtrl.text.replaceAll(',', '.'),
                              );
                              final m = Material3D(
                                id:
                                    material?.id ??
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                name: nameCtrl.text,
                                color: colorCtrl.text,
                                isResin: isResin,
                                cost: double.parse(
                                  costCtrl.text.replaceAll(',', '.'),
                                ),
                                totalQuantity: qtyVal,
                                remainingQuantity: material != null
                                    ? (material.remainingQuantity > qtyVal
                                          ? qtyVal
                                          : material.remainingQuantity)
                                    : qtyVal,
                                purchaseDate: tempPurchaseDate,
                                openDate: tempOpenDate,
                              );
                              if (material == null) {
                                appState.addMaterial(m);
                              } else {
                                appState.updateMaterial(m);
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
                            material == null
                                ? appState.translate('save_material')
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

  void _showRefillDialog(BuildContext context, Material3D material) {
    final qtyCtrl = TextEditingController(
      text: material.totalQuantity.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            appState.translate('refill_material'),
            style: const TextStyle(color: Colors.cyanAccent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa la cantidad actual disponible de ${material.name} (Capacidad total: ${material.totalQuantity.round()}${material.isResin ? 'ml' : 'g'}):',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: material.isResin
                      ? 'Cantidad en ml'
                      : 'Cantidad en gramos',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                appState.translate('cancel'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final double? val = double.tryParse(
                  qtyCtrl.text.replaceAll(',', '.'),
                );
                if (val != null && val >= 0) {
                  appState.updateMaterialRemaining(material.id, val);
                  Navigator.pop(ctx);
                }
              },
              child: Text(appState.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteMaterial(BuildContext context, Material3D material) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            appState.translate('delete_material'),
            style: const TextStyle(color: Colors.redAccent),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${material.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                appState.translate('cancel'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                appState.deleteMaterial(material.id);
                Navigator.pop(ctx);
              },
              child: Text(appState.translate('spool_delete')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialList(
    BuildContext context,
    List<Material3D> list,
    String emptyMsg,
  ) {
    if (list.isEmpty) {
      return Center(child: Text(emptyMsg));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final material = list[index];
        final double ratio = material.totalQuantity > 0
            ? (material.remainingQuantity / material.totalQuantity)
            : 0.0;
        final double percent = ratio * 100;

        Color progressColor = Colors.greenAccent;
        if (ratio < 0.2) {
          progressColor = Colors.redAccent;
        } else if (ratio < 0.5) {
          progressColor = Colors.orangeAccent;
        }

        final unit = material.isResin ? "ml" : "g";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white10),
          ),
          color: const Color(0xFF1E293B),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          material.isResin
                              ? Icons.water_drop
                              : Icons.filter_vintage,
                          color: progressColor,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Color: ${material.color}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.cyanAccent,
                          ),
                          tooltip: 'Editar Material',
                          onPressed: () =>
                              _showMaterialModal(context, material: material),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.replay,
                            color: Colors.cyanAccent,
                          ),
                          tooltip: 'Recargar Bobina/Tina',
                          onPressed: () => _showRefillDialog(context, material),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Eliminar Material',
                          onPressed: () =>
                              _confirmDeleteMaterial(context, material),
                        ),
                      ],
                    ),
                  ],
                ),
                if (material.purchaseDate != null ||
                    material.openDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${material.purchaseDate != null ? "Compra: ${material.purchaseDate!.day}/${material.purchaseDate!.month}/${material.purchaseDate!.year}" : ""}'
                    '${material.purchaseDate != null && material.openDate != null ? "  |  " : ""}'
                    '${material.openDate != null ? "Apertura: ${material.openDate!.day}/${material.openDate!.month}/${material.openDate!.year}" : ""}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${material.isResin ? "Resina" : "Filamento"} | Costo: ${appState.format(material.cost)}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      '${material.remainingQuantity.round()}$unit / ${material.totalQuantity.round()}$unit (${percent.round()}%)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            appState.translate('materials'),
            style: const TextStyle(color: Colors.cyanAccent),
          ),
          bottom: TabBar(
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(
                text: appState.translate('filaments'),
                icon: const Icon(Icons.filter_vintage),
              ),
              Tab(
                text: appState.translate('resins'),
                icon: const Icon(Icons.water_drop),
              ),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, child) {
            final filaments = appState.materials
                .where((m) => !m.isResin)
                .toList();
            final resins = appState.materials.where((m) => m.isResin).toList();

            return TabBarView(
              children: [
                _buildMaterialList(
                  context,
                  filaments,
                  'No hay filamentos registrados',
                ),
                _buildMaterialList(
                  context,
                  resins,
                  'No hay resinas registradas',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showMaterialModal(context),
          backgroundColor: Colors.cyanAccent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}
