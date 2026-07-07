import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../state/app_state.dart';
import '../models/project.dart';
import '../models/print_bed.dart';
import '../services/pdf_service.dart';
import '../widgets/print_bed_modal.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _currentProject;

  late TextEditingController _nameCtrl;
  late TextEditingController _referenceUrlCtrl;
  late TextEditingController _imagePathCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _clientNameCtrl;
  late TextEditingController _clientContactCtrl;
  late TextEditingController _collectionNameCtrl;

  // Mano de Obra
  late TextEditingController _prepTimeCtrl;
  late TextEditingController _prepCostCtrl;
  late TextEditingController _postTimeCtrl;
  late TextEditingController _postCostCtrl;

  // Costos adicionales
  late List<Map<String, dynamic>> _additionalCosts;
  final _newCostNameCtrl = TextEditingController();
  final _newCostValCtrl = TextEditingController();

  late double _margin;
  late bool _includeIva;
  late String _status;
  late List<PrintBed> _localBeds;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;

    _nameCtrl = TextEditingController(text: _currentProject.name);
    _referenceUrlCtrl = TextEditingController(
      text: _currentProject.referenceUrl,
    );
    _imagePathCtrl = TextEditingController(text: _currentProject.imagePath);
    _notesCtrl = TextEditingController(text: _currentProject.notes);
    _clientNameCtrl = TextEditingController(text: _currentProject.clientName);
    _clientContactCtrl = TextEditingController(
      text: _currentProject.clientContact,
    );
    _collectionNameCtrl = TextEditingController(
      text: _currentProject.collectionName,
    );

    _prepTimeCtrl = TextEditingController(
      text: _currentProject.preparationTimeMinutes.toString(),
    );
    _prepCostCtrl = TextEditingController(
      text: _currentProject.preparationCostPerHour.toString(),
    );
    _postTimeCtrl = TextEditingController(
      text: _currentProject.postProcessingTimeMinutes.toString(),
    );
    _postCostCtrl = TextEditingController(
      text: _currentProject.postProcessingCostPerHour.toString(),
    );

    _additionalCosts = List.from(_currentProject.additionalCosts);
    _localBeds = List.from(_currentProject.printBeds);
    _margin = _currentProject.marginPercent;
    _includeIva = _currentProject.includeIva;
    _status = _currentProject.status;
  }

  Future<void> _saveChanges() async {
    final updatedProject = Project(
      id: _currentProject.id,
      name: _nameCtrl.text,
      imagePath: _imagePathCtrl.text,
      printBeds: _localBeds,
      laborCost: _currentProject.laborCost,
      marginPercent: _margin,
      notes: _notesCtrl.text,
      deliveryDate: _currentProject.deliveryDate,
      deliveryTime: _currentProject.deliveryTime,
      priority: _currentProject.priority,
      hasSanding: _currentProject.hasSanding,
      hasPainting: _currentProject.hasPainting,
      preparationTimeMinutes: int.tryParse(_prepTimeCtrl.text) ?? 0,
      preparationCostPerHour: double.tryParse(_prepCostCtrl.text) ?? 0.0,
      postProcessingTimeMinutes: int.tryParse(_postTimeCtrl.text) ?? 0,
      postProcessingCostPerHour: double.tryParse(_postCostCtrl.text) ?? 0.0,
      additionalCosts: List.from(_additionalCosts),
      includeIva: _includeIva,
      ivaPercent: _currentProject.ivaPercent,
      status: _status,
      referenceUrl: _referenceUrlCtrl.text,
      clientName: _clientNameCtrl.text,
      clientContact: _clientContactCtrl.text,
      collectionName: _collectionNameCtrl.text,
    );

    await appState.updateProjectState(updatedProject);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.translate('project_updated'),
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      setState(() {
        _currentProject = updatedProject;
      });
    }
  }

  void _showAddOrEditPrintBedModal(BuildContext context, int? indexToEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) {
        return PrintBedModal(
          printBed: indexToEdit != null ? _localBeds[indexToEdit] : null,
          index: indexToEdit ?? _localBeds.length,
          onSave: (updatedBed) {
            setState(() {
              if (indexToEdit == null) {
                _localBeds.add(updatedBed);
              } else {
                _localBeds[indexToEdit] = updatedBed;
              }
            });
            _saveChanges();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double materialsCost = _localBeds.fold(
      0.0,
      (sum, bed) => sum + bed.getMaterialCost(),
    );
    double electricityCost = _localBeds.fold(
      0.0,
      (sum, bed) => sum + bed.getElectricityCost(appState.electricityPriceKwh),
    );
    double depreciationCost = _localBeds.fold(
      0.0,
      (sum, bed) => sum + bed.getDepreciation(),
    );
    double laborCost =
        (((int.tryParse(_prepTimeCtrl.text) ?? 0) / 60.0) *
            (double.tryParse(_prepCostCtrl.text) ?? 0.0)) +
        (((int.tryParse(_postTimeCtrl.text) ?? 0) / 60.0) *
            (double.tryParse(_postCostCtrl.text) ?? 0.0));
    double additionalCostSum = _additionalCosts.fold(
      0.0,
      (sum, item) => sum + (item['cost'] as num).toDouble(),
    );
    double totalCost =
        materialsCost +
        electricityCost +
        depreciationCost +
        laborCost +
        additionalCostSum;
    double salePriceBeforeIva = totalCost * (1 + (_margin / 100));
    double ivaCost = _includeIva
        ? (salePriceBeforeIva * (_currentProject.ivaPercent / 100.0))
        : 0.0;
    double finalPrice = salePriceBeforeIva + ivaCost;

    String dateStr = _currentProject.deliveryDate != null
        ? "${_currentProject.deliveryDate!.day}/${_currentProject.deliveryDate!.month}/${_currentProject.deliveryDate!.year}"
        : "Sin fecha";
    String timeStr = _currentProject.deliveryTime != null
        ? _currentProject.deliveryTime!.format(context)
        : "";

    Widget imageWidget = const SizedBox.shrink();
    if (_currentProject.referenceUrl.isNotEmpty &&
        (_currentProject.referenceUrl.startsWith('http://') ||
            _currentProject.referenceUrl.startsWith('https://'))) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _currentProject.referenceUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 80,
            color: Colors.white10,
            child: const Center(
              child: Text(
                'No se pudo cargar la imagen de referencia (URL)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    } else if (_currentProject.imagePath.isNotEmpty) {
      final file = File(_currentProject.imagePath);
      if (file.existsSync()) {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appState.translate('edit_project'),
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir Resumen Texto',
            onPressed: () {
              String resumen =
                  '''
📦 Proyecto: ${_currentProject.name}
⚡ Prioridad: ${_currentProject.priority}
📊 Estado: ${appState.translate(_status).toUpperCase()}
🗓️ Entrega: $dateStr $timeStr
--------------------------
💰 Costo Producción: ${appState.format(totalCost)}
🏷️ Precio Venta Sugerido: ${appState.format(finalPrice)} ${_currentProject.includeIva ? '(IVA incl.)' : ''}
              ''';
              Clipboard.setData(ClipboardData(text: resumen));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    appState.translate('undo') + ' (resumen copiado)',
                    style: const TextStyle(color: Colors.black),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.orangeAccent),
            tooltip: 'Exportar PDF',
            onPressed: () {
              _saveChanges();
              PdfService.generateAndShareQuote(
                _currentProject,
                appState.electricityPriceKwh,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar Cambios',
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageWidget is! SizedBox) ...[
              imageWidget,
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: appState.translate('name_project'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _collectionNameCtrl,
              decoration: InputDecoration(
                labelText: appState.translate('collection'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.folder_open),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _clientNameCtrl,
                    decoration: InputDecoration(
                      labelText: appState.translate('client_name'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _clientContactCtrl,
                    decoration: InputDecoration(
                      labelText: appState.translate('client_contact'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceUrlCtrl,
              decoration: InputDecoration(
                labelText: appState.translate('ref_url'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                labelText: appState.translate('state'),
                border: const OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF1E293B),
              items: [
                DropdownMenuItem(
                  value: 'pendiente',
                  child: Text(appState.translate('pendiente')),
                ),
                DropdownMenuItem(
                  value: 'enProceso',
                  child: Text(appState.translate('enProceso')),
                ),
                DropdownMenuItem(
                  value: 'terminado',
                  child: Text(appState.translate('terminado')),
                ),
                DropdownMenuItem(
                  value: 'propio',
                  child: Text(appState.translate('own_project')),
                ),
                DropdownMenuItem(
                  value: 'independiente',
                  child: Text(appState.translate('independiente')),
                ),
                DropdownMenuItem(
                  value: 'cancelado',
                  child: Text(appState.translate('cancelado')),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _status = val);
                }
              },
            ),
            const SizedBox(height: 12),
            if (_status != 'propio' &&
                _status != 'independiente' &&
                _status != 'cancelado') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  appState.translate('delivery_date'),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                subtitle: Text("$dateStr $timeStr"),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.date_range,
                    color: Colors.orangeAccent,
                  ),
                  onPressed: () async {
                    DateTime? tempDate = await showDatePicker(
                      context: context,
                      initialDate:
                          _currentProject.deliveryDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (tempDate != null) {
                      if (!context.mounted) return;
                      TimeOfDay? tempTime = await showTimePicker(
                        context: context,
                        initialTime:
                            _currentProject.deliveryTime ?? TimeOfDay.now(),
                      );
                      setState(() {
                        _currentProject.deliveryDate = tempDate;
                        if (tempTime != null) {
                          _currentProject.deliveryTime = tempTime;
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: appState.translate('notes'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // SECCIÓN MENÚS ABATIBLES (EXPANSION TILES)
            Text(
              appState.translate('financial_summary') + ':',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            // 1. Camas de Impresión
            ExpansionTile(
              leading: Icon(Icons.extension, color: Theme.of(context).colorScheme.primary),
              title: Text('Camas de Impresión (${_localBeds.length})'),
              subtitle: Text(
                'Costo Materiales: ${appState.format(materialsCost)}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddOrEditPrintBedModal(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Cama de Impresión'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
                ..._localBeds.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final bed = entry.value;
                  return Card(
                    color: const Color(0xFF334155),
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 16,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  bed.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    appState.format(
                                      bed.getTotalCost(
                                        appState.electricityPriceKwh,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () =>
                                        _showAddOrEditPrintBedModal(
                                          context,
                                          idx,
                                        ),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Confirmar Eliminación',
                                          ),
                                          content: const Text(
                                            '¿Deseas eliminar esta cama de impresión y todos sus objetos?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: Text(
                                                appState.translate('cancel'),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _localBeds.removeAt(idx);
                                                });
                                                Navigator.pop(ctx);
                                                _saveChanges();
                                              },
                                              child: const Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${appState.translate('printer_label')}: ${bed.printer.name}',
                          ),
                          Text(
                            '${appState.translate('material_label')}: ${bed.material.name} - ${bed.material.color}',
                          ),
                          Text(
                            'Tiempo de impresión: ${bed.printHours}h ${bed.printMinutes}m',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Piezas en la Cama:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          ...bed.pieces.map((p) {
                            final u = bed.printer.isResin ? 'ml' : 'g';
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                top: 2.0,
                              ),
                              child: Text(
                                '- ${p.name}: ${p.totalMaterialUsed.round()}$u (Base: ${p.quantityUsed}$u) | ${p.slicerConfig.summary}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),

            // 2. Consumo Eléctrico
            ExpansionTile(
              leading: const Icon(Icons.bolt, color: Colors.yellowAccent),
              title: Text(appState.translate('electricity')),
              subtitle: Text('Total: ${appState.format(electricityCost)}'),
              children: _localBeds.map((bed) {
                final electricity = bed.getElectricityCost(
                  appState.electricityPriceKwh,
                );
                return ListTile(
                  title: Text(bed.name),
                  subtitle: Text(
                    '${bed.printer.name} (${bed.printer.powerW}W) por ${bed.printHours}h ${bed.printMinutes}m a ${appState.format(appState.electricityPriceKwh)}/kWh',
                  ),
                  trailing: Text(appState.format(electricity)),
                );
              }).toList(),
            ),

            // 3. Depreciación de Impresoras
            ExpansionTile(
              leading: const Icon(Icons.trending_down, color: Colors.redAccent),
              title: Text(appState.translate('depreciation')),
              subtitle: Text('Total: ${appState.format(depreciationCost)}'),
              children: _localBeds.map((bed) {
                final dep = bed.getDepreciation();
                return ListTile(
                  title: Text(bed.name),
                  subtitle: Text(
                    '${bed.printer.name} (${appState.translate('printer_cost')}: ${appState.format(bed.printer.cost)} | ${appState.translate('printer_life')}: ${bed.printer.lifespanH.round()}h) por ${bed.printHours}h ${bed.printMinutes}m',
                  ),
                  trailing: Text(appState.format(dep)),
                );
              }).toList(),
            ),

            // 4. Mano de Obra y Post-procesado
            ExpansionTile(
              leading: const Icon(Icons.build, color: Colors.lightGreenAccent),
              title: Text(
                '${appState.translate('preparation')} & ${appState.translate('post_processing')}',
              ),
              subtitle: Text('Total: ${appState.format(laborCost)}'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _prepTimeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate(
                                  'preparation_time',
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _prepCostCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate(
                                  'preparation_rate',
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _postTimeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('post_time'),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _postCostCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('post_rate'),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 5. Costos Adicionales (Extras)
            ExpansionTile(
              leading: const Icon(Icons.add_circle, color: Colors.orangeAccent),
              title: Text(appState.translate('additional_costs')),
              subtitle: Text('Total: ${appState.format(additionalCostSum)}'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._additionalCosts.asMap().entries.map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.value['name']),
                          subtitle: Text(
                            'Costo: ${appState.format(entry.value['cost'])}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                _additionalCosts.removeAt(entry.key);
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _newCostNameCtrl,
                              decoration: InputDecoration(
                                labelText: appState.translate(
                                  'extra_name_hint',
                                ),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _newCostValCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState
                                    .translate('extra_cost_label')
                                    .replaceAll(' (\$)', ''),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () {
                              if (_newCostNameCtrl.text.isNotEmpty &&
                                  _newCostValCtrl.text.isNotEmpty) {
                                final costVal =
                                    double.tryParse(_newCostValCtrl.text) ??
                                    0.0;
                                setState(() {
                                  _additionalCosts.add({
                                    'name': _newCostNameCtrl.text,
                                    'cost': costVal,
                                  });
                                  _newCostNameCtrl.clear();
                                  _newCostValCtrl.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),

            // 6. Desglose Financiero & IVA
            ExpansionTile(
              leading: const Icon(
                Icons.attach_money,
                color: Colors.greenAccent,
              ),
              title: Text(appState.translate('financial_summary_title')),
              subtitle: Text(
                '${appState.translate('suggested_final')} ${appState.format(finalPrice)} ${_includeIva ? '(IVA incl.)' : ''}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(appState.translate('vat_toggle')),
                        value: _includeIva,
                        onChanged: (val) {
                          setState(() => _includeIva = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${appState.translate('profit_margin')} ${_margin.toInt()}%',
                      ),
                      slider(
                        value: _margin,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        activeColor: Colors.orangeAccent,
                        onChanged: (val) => setState(() {
                          _margin = val;
                        }),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Costo Fabricación Base:',
                              totalCost,
                            ),
                            _buildSummaryRow(
                              appState.translate('profit_margin'),
                              salePriceBeforeIva - totalCost,
                            ),
                            if (_includeIva) ...[
                              _buildSummaryRow(
                                appState.translate('neto'),
                                salePriceBeforeIva,
                              ),
                              _buildSummaryRow(
                                appState.translate('vat_amount'),
                                ivaCost,
                              ),
                            ],
                            Divider(color: Theme.of(context).colorScheme.primary),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  appState.translate('final_price'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  appState.format(finalPrice),
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
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _saveChanges();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                appState.translate('save_changes'),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            appState.format(amount),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // Helper widget to bypass compiler capitalization issues if Slider is renamed.
  Widget slider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor,
      onChanged: onChanged,
    );
  }
}
