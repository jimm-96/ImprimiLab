import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../state/app_state.dart';
import '../models/project.dart';
import '../models/print_bed.dart';
import '../models/piece.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/slicer_config.dart';
import '../services/pdf_service.dart';

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

  void _saveChanges() {
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

    appState.updateProjectState(updatedProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appState.translate('project_updated'),
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.cyanAccent,
      ),
    );
    setState(() {
      _currentProject = updatedProject;
    });
  }

  void _showAddOrEditPrintBedModal(BuildContext context, int? indexToEdit) {
    if (appState.printers.isEmpty || appState.materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.translate('no_printers_mats'))),
      );
      return;
    }

    final bed = indexToEdit != null ? _localBeds[indexToEdit] : null;

    final nameCtrl = TextEditingController(
      text: bed?.name ?? 'Cama ${_localBeds.length + 1}',
    );
    final hoursCtrl = TextEditingController(
      text: bed?.printHours.toString() ?? '0',
    );
    final minutesCtrl = TextEditingController(
      text: bed?.printMinutes.toString() ?? '0',
    );

    Printer? selectedPrinter;
    if (bed != null) {
      selectedPrinter = appState.printers.firstWhere(
        (p) => p.id == bed.printer.id,
        orElse: () => appState.printers.where((p) => p.isEnabled).first,
      );
    } else {
      selectedPrinter = appState.printers.any((p) => p.isEnabled)
          ? appState.printers.firstWhere((p) => p.isEnabled)
          : (appState.printers.isNotEmpty ? appState.printers.first : null);
    }

    Material3D? selectedMaterial;
    if (bed != null) {
      selectedMaterial = appState.materials.firstWhere(
        (m) => m.id == bed.material.id,
        orElse: () => appState.materials.first,
      );
    } else if (selectedPrinter != null) {
      selectedMaterial = appState.materials.firstWhere(
        (m) => m.isResin == selectedPrinter!.isResin,
        orElse: () => appState.materials.first,
      );
    }

    final List<Piece> tempPieces = bed != null ? List.from(bed.pieces) : [];

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      indexToEdit == null
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
                      items: appState.printers
                          .where(
                            (p) => p.isEnabled || p.id == selectedPrinter?.id,
                          )
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setStateModal(() {
                          selectedPrinter = v;
                          if (selectedPrinter != null) {
                            final compatibleMats = appState.materials
                                .where(
                                  (m) => m.isResin == selectedPrinter!.isResin,
                                )
                                .toList();
                            if (selectedMaterial != null &&
                                !compatibleMats.any(
                                  (m) => m.id == selectedMaterial!.id,
                                )) {
                              selectedMaterial = compatibleMats.isNotEmpty
                                  ? compatibleMats.first
                                  : null;
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
                          .where(
                            (m) => selectedPrinter == null
                                ? true
                                : m.isResin == selectedPrinter!.isResin,
                          )
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text('${m.name} (${m.color})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setStateModal(() => selectedMaterial = v);
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

                    // Lista de piezas en esta cama
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
                          onPressed: () => _showPieceSubModal(
                            context,
                            setStateModal,
                            tempPieces,
                            null,
                            selectedPrinter!.isResin,
                          ),
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
                      final unit = selectedPrinter!.isResin ? 'ml' : 'g';
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
                                onPressed: () => _showPieceSubModal(
                                  context,
                                  setStateModal,
                                  tempPieces,
                                  pIdx,
                                  selectedPrinter!.isResin,
                                ),
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
                                  setStateModal(() {
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
                                selectedPrinter == null ||
                                selectedMaterial == null) {
                              return;
                            }
                            final newBed = PrintBed(
                              id:
                                  bed?.id ??
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              name: nameCtrl.text,
                              printer: selectedPrinter!,
                              material: selectedMaterial!,
                              printHours: int.tryParse(hoursCtrl.text) ?? 0,
                              printMinutes: int.tryParse(minutesCtrl.text) ?? 0,
                              pieces: List.from(tempPieces),
                            );

                            setState(() {
                              if (indexToEdit == null) {
                                _localBeds.add(newBed);
                              } else {
                                _localBeds[indexToEdit] = newBed;
                              }
                            });
                            Navigator.pop(ctx);
                            _saveChanges();
                          },
                          child: Text(appState.translate('save')),
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

  void _showPieceSubModal(
    BuildContext context,
    StateSetter setStateParent,
    List<Piece> tempPiecesList,
    int? pieceIdxToEdit,
    bool isResin,
  ) {
    final piece = pieceIdxToEdit != null
        ? tempPiecesList[pieceIdxToEdit]
        : null;

    final nameCtrl = TextEditingController(text: piece?.name ?? '');
    final qtyCtrl = TextEditingController(
      text: piece?.quantityUsed.toString() ?? '',
    );
    final lossValueCtrl = TextEditingController(
      text: piece?.lossValue.toString() ?? '0',
    );
    final profileNameCtrl = TextEditingController(
      text: piece?.slicerConfig.profileName ?? "Default",
    );

    bool hasSupports = piece?.slicerConfig.hasSupports ?? false;
    final supportTypeCtrl = TextEditingController(
      text: piece?.slicerConfig.supportType ?? '',
    );

    final fdmLayerCtrl = TextEditingController(
      text: piece?.slicerConfig is FdmSlicerConfig
          ? (piece!.slicerConfig as FdmSlicerConfig).layerHeight.toString()
          : "0.2",
    );
    final fdmInfillCtrl = TextEditingController(
      text: piece?.slicerConfig is FdmSlicerConfig
          ? (piece!.slicerConfig as FdmSlicerConfig).infillPercent.toString()
          : "15",
    );
    final fdmNozzleTempCtrl = TextEditingController(
      text: piece?.slicerConfig is FdmSlicerConfig
          ? (piece!.slicerConfig as FdmSlicerConfig).nozzleTemp.toString()
          : "210",
    );
    final fdmBedTempCtrl = TextEditingController(
      text: piece?.slicerConfig is FdmSlicerConfig
          ? (piece!.slicerConfig as FdmSlicerConfig).bedTemp.toString()
          : "60",
    );

    final resinLayerCtrl = TextEditingController(
      text: piece?.slicerConfig is ResinSlicerConfig
          ? (piece!.slicerConfig as ResinSlicerConfig).layerHeight.toString()
          : "0.05",
    );
    final resinNormalExpCtrl = TextEditingController(
      text: piece?.slicerConfig is ResinSlicerConfig
          ? (piece!.slicerConfig as ResinSlicerConfig).normalExposure.toString()
          : "2.5",
    );
    final resinBottomExpCtrl = TextEditingController(
      text: piece?.slicerConfig is ResinSlicerConfig
          ? (piece!.slicerConfig as ResinSlicerConfig).bottomExposure.toString()
          : "25.0",
    );
    final resinBottomLayersCtrl = TextEditingController(
      text: piece?.slicerConfig is ResinSlicerConfig
          ? (piece!.slicerConfig as ResinSlicerConfig).bottomLayers.toString()
          : "6",
    );

    bool isLossPercent = piece?.isLossPercent ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStatePieceModal) {
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pieceIdxToEdit == null
                          ? 'Añadir Objeto a la Cama'
                          : 'Editar Objeto en la Cama',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: appState.translate('piece_name_label'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isResin
                                  ? '${appState.translate('consumption_base')} (ml)'
                                  : '${appState.translate('consumption_base')} (g)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<bool>(
                            value: isLossPercent,
                            decoration: InputDecoration(
                              labelText: appState.translate('loss_type'),
                            ),
                            dropdownColor: const Color(0xFF1E293B),
                            items: [
                              const DropdownMenuItem(
                                value: true,
                                child: Text('Porcentaje (%)'),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text('Fijo (${isResin ? 'ml' : 'g'})'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setStatePieceModal(() => isLossPercent = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: lossValueCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: appState.translate('loss_value'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    Text(
                      appState.translate('add_piece_modal'),
                      style: const TextStyle(color: Colors.cyanAccent),
                    ),
                    TextField(
                      controller: profileNameCtrl,
                      decoration: InputDecoration(
                        labelText: appState.translate('profile_name'),
                      ),
                    ),
                    SwitchListTile(
                      title: Text(appState.translate('has_supports')),
                      value: hasSupports,
                      onChanged: (val) =>
                          setStatePieceModal(() => hasSupports = val),
                    ),
                    if (hasSupports)
                      TextField(
                        controller: supportTypeCtrl,
                        decoration: InputDecoration(
                          labelText: appState.translate('support_type'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (isResin) ...[
                      Text(
                        appState.translate('resin_params'),
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: resinLayerCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('layer_height'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: resinNormalExpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('normal_exp'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: resinBottomExpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('bottom_exp'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: resinBottomLayersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('bottom_layers'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        appState.translate('fdm_params'),
                        style: const TextStyle(color: Colors.lightGreenAccent),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fdmLayerCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('layer_height'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fdmInfillCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('infill'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fdmNozzleTempCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('nozzle_temp'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fdmBedTempCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: appState.translate('bed_temp'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                            if (nameCtrl.text.isEmpty || qtyCtrl.text.isEmpty)
                              return;
                            try {
                              SlicerConfig config;
                              if (isResin) {
                                config = ResinSlicerConfig(
                                  profileName: profileNameCtrl.text,
                                  hasSupports: hasSupports,
                                  supportType: supportTypeCtrl.text,
                                  layerHeight: double.parse(
                                    resinLayerCtrl.text.replaceAll(',', '.'),
                                  ),
                                  normalExposure: double.parse(
                                    resinNormalExpCtrl.text.replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  ),
                                  bottomExposure: double.parse(
                                    resinBottomExpCtrl.text.replaceAll(
                                      ',',
                                      '.',
                                    ),
                                  ),
                                  bottomLayers: int.parse(
                                    resinBottomLayersCtrl.text,
                                  ),
                                );
                              } else {
                                config = FdmSlicerConfig(
                                  profileName: profileNameCtrl.text,
                                  hasSupports: hasSupports,
                                  supportType: supportTypeCtrl.text,
                                  layerHeight: double.parse(
                                    fdmLayerCtrl.text.replaceAll(',', '.'),
                                  ),
                                  infillPercent: double.parse(
                                    fdmInfillCtrl.text.replaceAll(',', '.'),
                                  ),
                                  nozzleTemp: double.parse(
                                    fdmNozzleTempCtrl.text.replaceAll(',', '.'),
                                  ),
                                  bedTemp: double.parse(
                                    fdmBedTempCtrl.text.replaceAll(',', '.'),
                                  ),
                                );
                              }

                              final p = Piece(
                                name: nameCtrl.text,
                                quantityUsed: double.parse(
                                  qtyCtrl.text.replaceAll(',', '.'),
                                ),
                                isLossPercent: isLossPercent,
                                lossValue: double.parse(
                                  lossValueCtrl.text.replaceAll(',', '.'),
                                ),
                                slicerConfig: config,
                              );

                              setStateParent(() {
                                if (pieceIdxToEdit == null) {
                                  tempPiecesList.add(p);
                                } else {
                                  tempPiecesList[pieceIdxToEdit] = p;
                                }
                              });
                              Navigator.pop(ctx);
                            } catch (e) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    appState.translate('invalid_number'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(appState.translate('save')),
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
          style: const TextStyle(color: Colors.cyanAccent),
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
                  backgroundColor: Colors.cyanAccent,
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
                  style: const TextStyle(color: Colors.cyanAccent),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: 10),

            // 1. Camas de Impresión
            ExpansionTile(
              leading: const Icon(Icons.extension, color: Colors.cyanAccent),
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
                      side: const BorderSide(color: Colors.cyanAccent),
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
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.cyanAccent,
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
                          const Text(
                            'Piezas en la Cama:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
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
                            const Divider(color: Colors.cyanAccent),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  appState.translate('final_price'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyanAccent,
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
                backgroundColor: Colors.cyanAccent,
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
