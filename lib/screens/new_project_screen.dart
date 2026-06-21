import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../models/project.dart';
import '../models/print_bed.dart';
import '../models/piece.dart';
import '../models/printer.dart';
import '../models/material3d.dart';
import '../models/slicer_config.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _referenceUrlController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientContactController = TextEditingController();
  final _collectionNameController = TextEditingController();

  // Mano de obra
  final _prepTimeController = TextEditingController(text: '0');
  final _prepCostController = TextEditingController(text: '0');
  final _postTimeController = TextEditingController(text: '0');
  final _postCostController = TextEditingController(text: '0');

  // Adicionales
  final List<Map<String, dynamic>> _additionalCosts = [];
  final _newCostNameController = TextEditingController();
  final _newCostValController = TextEditingController();

  double _margin = 100.0;
  bool _includeIva = false;
  double _ivaPercent = 19.0;
  String _status =
      'pendiente'; // 'pendiente', 'enProceso', 'terminado', 'propio', 'independiente'

  final List<PrintBed> _projectPrintBeds = [];
  DateTime? _tempDeliveryDate;
  TimeOfDay? _tempDeliveryTime;
  String _priority = 'Media';
  bool _hasSanding = false;
  bool _hasPainting = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _includeIva = appState.defaultTaxRate > 0;
    _ivaPercent = appState.defaultTaxRate;
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString('draft_name') ?? '';
        _referenceUrlController.text =
            prefs.getString('draft_reference_url') ?? '';
        _clientNameController.text = prefs.getString('draft_client_name') ?? '';
        _clientContactController.text =
            prefs.getString('draft_client_contact') ?? '';
        _collectionNameController.text =
            prefs.getString('draft_collection_name') ?? '';
        _prepTimeController.text = prefs.getString('draft_prep_time') ?? '0';
        _prepCostController.text = prefs.getString('draft_prep_cost') ?? '0';
        _postTimeController.text = prefs.getString('draft_post_time') ?? '0';
        _postCostController.text = prefs.getString('draft_post_cost') ?? '0';
        _includeIva =
            prefs.getBool('draft_include_iva') ?? (appState.defaultTaxRate > 0);
        _status = prefs.getString('draft_status') ?? 'pendiente';
        _margin = prefs.getDouble('draft_margin') ?? 100.0;

        final rawAddCosts = prefs.getString('draft_additional_costs');
        if (rawAddCosts != null) {
          final List<dynamic> decoded = json.decode(rawAddCosts);
          _additionalCosts.clear();
          _additionalCosts.addAll(
            decoded.map((item) => Map<String, dynamic>.from(item)).toList(),
          );
        }

        final rawBeds = prefs.getString('draft_print_beds');
        if (rawBeds != null) {
          final List<dynamic> decoded = json.decode(rawBeds);
          _projectPrintBeds.clear();
          _projectPrintBeds.addAll(
            decoded.map((item) => PrintBed.fromJson(item)).toList(),
          );
        }

        _priority = prefs.getString('draft_priority') ?? 'Media';
        _hasSanding = prefs.getBool('draft_sanding') ?? false;
        _hasPainting = prefs.getBool('draft_painting') ?? false;

        String? imagePath = prefs.getString('draft_image');
        if (imagePath != null && imagePath.isNotEmpty) {
          if (!kIsWeb) {
            final file = File(imagePath);
            if (file.existsSync()) {
              _imageController.text = imagePath;
              _selectedImage = file;
            } else {
              prefs.remove('draft_image');
            }
          } else {
            _imageController.text = imagePath;
          }
        }
      });
    } catch (e) {
      debugPrint("Error al cargar borrador: $e");
    }
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_name', _nameController.text);
      await prefs.setString(
        'draft_reference_url',
        _referenceUrlController.text,
      );
      await prefs.setString('draft_client_name', _clientNameController.text);
      await prefs.setString(
        'draft_client_contact',
        _clientContactController.text,
      );
      await prefs.setString(
        'draft_collection_name',
        _collectionNameController.text,
      );
      await prefs.setString('draft_prep_time', _prepTimeController.text);
      await prefs.setString('draft_prep_cost', _prepCostController.text);
      await prefs.setString('draft_post_time', _postTimeController.text);
      await prefs.setString('draft_post_cost', _postCostController.text);
      await prefs.setBool('draft_include_iva', _includeIva);
      await prefs.setString('draft_status', _status);
      await prefs.setDouble('draft_margin', _margin);
      await prefs.setString(
        'draft_additional_costs',
        json.encode(_additionalCosts),
      );
      await prefs.setString(
        'draft_print_beds',
        json.encode(_projectPrintBeds.map((b) => b.toJson()).toList()),
      );
      await prefs.setString('draft_priority', _priority);
      await prefs.setBool('draft_sanding', _hasSanding);
      await prefs.setBool('draft_painting', _hasPainting);
      await prefs.setString('draft_image', _imageController.text);
    } catch (e) {
      debugPrint("Error al guardar borrador: $e");
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() {
        _imageController.text = pickedFile.path;
        if (!kIsWeb) {
          _selectedImage = File(pickedFile.path);
        }
      });
      _saveDraft();
    }
  }

  void _saveProject() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.translate('invalid_number'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      imagePath: _imageController.text,
      printBeds: List.from(_projectPrintBeds),
      marginPercent: _margin,
      deliveryDate: _tempDeliveryDate,
      deliveryTime: _tempDeliveryTime,
      priority: _priority,
      hasSanding: _hasSanding,
      hasPainting: _hasPainting,
      preparationTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
      preparationCostPerHour: double.tryParse(_prepCostController.text) ?? 0.0,
      postProcessingTimeMinutes: int.tryParse(_postTimeController.text) ?? 0,
      postProcessingCostPerHour:
          double.tryParse(_postCostController.text) ?? 0.0,
      additionalCosts: List.from(_additionalCosts),
      includeIva: _includeIva,
      ivaPercent: _ivaPercent,
      status: _status,
      referenceUrl: _referenceUrlController.text,
      clientName: _clientNameController.text,
      clientContact: _clientContactController.text,
      collectionName: _collectionNameController.text,
    );

    appState.addProject(project);
    _clearDraft();
    Navigator.pop(context);
  }

  double getMaterialsCost() {
    return _projectPrintBeds.fold(
      0.0,
      (sum, bed) => sum + bed.getMaterialCost(),
    );
  }

  double getElectricityCost() {
    return _projectPrintBeds.fold(
      0.0,
      (sum, bed) => sum + bed.getElectricityCost(appState.electricityPriceKwh),
    );
  }

  double getDepreciationCost() {
    return _projectPrintBeds.fold(
      0.0,
      (sum, bed) => sum + bed.getDepreciation(),
    );
  }

  double getLaborCost() {
    double prep =
        ((double.tryParse(_prepTimeController.text) ?? 0) / 60.0) *
        (double.tryParse(_prepCostController.text) ?? 0);
    double post =
        ((double.tryParse(_postTimeController.text) ?? 0) / 60.0) *
        (double.tryParse(_postCostController.text) ?? 0);
    return prep + post;
  }

  double getAdditionalCostsSum() {
    return _additionalCosts.fold(
      0.0,
      (sum, item) => sum + (item['cost'] as num).toDouble(),
    );
  }

  double getTotalManufacturingCost() {
    return getMaterialsCost() +
        getElectricityCost() +
        getDepreciationCost() +
        getLaborCost() +
        getAdditionalCostsSum();
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = getTotalManufacturingCost();
    double salePriceBeforeIva = totalCost * (1 + (_margin / 100));
    double ivaCost = _includeIva
        ? (salePriceBeforeIva * (_ivaPercent / 100.0))
        : 0.0;
    double salePrice = salePriceBeforeIva + ivaCost;

    return Scaffold(
      appBar: AppBar(title: Text(appState.translate('new_project'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección 1: Información General
              Text(
                appState.translate('general_info'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: appState.translate('name_project'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
                onChanged: (_) => _saveDraft(),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _collectionNameController,
                decoration: InputDecoration(
                  labelText: appState.translate('collection'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.folder_open),
                ),
                onChanged: (_) => _saveDraft(),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clientNameController,
                      decoration: InputDecoration(
                        labelText: appState.translate('client_name'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      onChanged: (_) => _saveDraft(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _clientContactController,
                      decoration: InputDecoration(
                        labelText: appState.translate('client_contact'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      onChanged: (_) => _saveDraft(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _referenceUrlController,
                decoration: InputDecoration(
                  labelText: appState.translate('ref_url'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                ),
                onChanged: (_) => _saveDraft(),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageController,
                      decoration: InputDecoration(
                        labelText: appState.translate('local_photo'),
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library, color: Colors.black),
                    label: Text(
                      appState.translate('upload'),
                      style: const TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 15,
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedImage != null && !kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 15),

              // Tipo de Proyecto / Estado de venta
              Text(
                '${appState.translate('state')}:',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                    _saveDraft();
                  }
                },
              ),
              const SizedBox(height: 15),

              if (_status != 'propio' &&
                  _status != 'independiente' &&
                  _status != 'cancelado') ...[
                Text(
                  appState.translate('priority'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.cyanAccent,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          appState.translate('urgency_red'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: 'Alta',
                        groupValue: _priority,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) {
                          setState(() => _priority = v!);
                          _saveDraft();
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          appState.translate('urgency_yellow'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: 'Media',
                        groupValue: _priority,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) {
                          setState(() => _priority = v!);
                          _saveDraft();
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          appState.translate('urgency_green'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: 'Baja',
                        groupValue: _priority,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) {
                          setState(() => _priority = v!);
                          _saveDraft();
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],

              Text(
                'Servicios de Post-Procesado Rápido:',
                style: const TextStyle(fontSize: 15, color: Colors.cyanAccent),
              ),
              CheckboxListTile(
                title: Text(appState.translate('sanding_supports')),
                value: _hasSanding,
                dense: true,
                onChanged: (v) {
                  setState(() => _hasSanding = v!);
                  _saveDraft();
                },
              ),
              CheckboxListTile(
                title: Text(appState.translate('painting_priming')),
                value: _hasPainting,
                dense: true,
                onChanged: (v) {
                  setState(() => _hasPainting = v!);
                  _saveDraft();
                },
              ),
              const Divider(),

              if (_status != 'propio' &&
                  _status != 'independiente' &&
                  _status != 'cancelado') ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    appState.translate('delivery_date'),
                    style: const TextStyle(color: Colors.cyanAccent),
                  ),
                  subtitle: Text(
                    _tempDeliveryDate == null && _tempDeliveryTime == null
                        ? "No seleccionada"
                        : "${_tempDeliveryDate?.day}/${_tempDeliveryDate?.month}/${_tempDeliveryDate?.year} - ${_tempDeliveryTime?.format(context) ?? ''}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.date_range,
                      color: Colors.orangeAccent,
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        setState(() {
                          _tempDeliveryDate = date;
                          if (time != null) _tempDeliveryTime = time;
                        });
                      }
                    },
                  ),
                ),
                const Divider(),
              ],

              // Sección 2: Camas de Impresión
              const SizedBox(height: 10),
              Text(
                '2. Camas de Impresión',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 10),
              if (_projectPrintBeds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No hay camas agregadas. Agrega una cama de impresión.',
                  ),
                ),
              ..._projectPrintBeds.asMap().entries.map((entry) {
                final idx = entry.key;
                final bed = entry.value;
                return Card(
                  color: const Color(0xFF334155),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      bed.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${bed.printer.name} | ${bed.material.name} (${bed.material.color})\nTiempo: ${bed.printHours}h ${bed.printMinutes}m | Piezas: ${bed.pieces.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.cyanAccent,
                          ),
                          onPressed: () => _showPrintBedModal(context, idx),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              _projectPrintBeds.removeAt(idx);
                            });
                            _saveDraft();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showPrintBedModal(context, null),
                icon: const Icon(Icons.add_box),
                label: const Text('Agregar Cama de Impresión'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
              const Divider(),

              // Sección 3: Mano de Obra Desglosada
              const SizedBox(height: 10),
              Text(
                appState.translate('labor_section'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: appState.translate('preparation_time'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _saveDraft();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _prepCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: appState.translate('preparation_rate'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _saveDraft();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: appState.translate('post_time'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _saveDraft();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _postCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: appState.translate('post_rate'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _saveDraft();
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Sección 4: Costos Adicionales
              const SizedBox(height: 10),
              Text(
                appState.translate('extras_section'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 10),
              if (_additionalCosts.isEmpty)
                Text(
                  appState.translate('no_extras'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _additionalCosts
                    .asMap()
                    .entries
                    .map(
                      (entry) => Chip(
                        label: Text(
                          '${entry.value['name']}: ${appState.format(entry.value['cost'])}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.white10,
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                        onDeleted: () {
                          setState(() {
                            _additionalCosts.removeAt(entry.key);
                          });
                          _saveDraft();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _newCostNameController,
                      decoration: InputDecoration(
                        labelText: appState.translate('extra_name_hint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _newCostValController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: appState.translate('extra_cost_label'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      if (_newCostNameController.text.isNotEmpty &&
                          _newCostValController.text.isNotEmpty) {
                        final cost =
                            double.tryParse(_newCostValController.text) ?? 0.0;
                        setState(() {
                          _additionalCosts.add({
                            'name': _newCostNameController.text,
                            'cost': cost,
                          });
                          _newCostNameController.clear();
                          _newCostValController.clear();
                        });
                        _saveDraft();
                      }
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Sección 5: Financiero e IVA
              const SizedBox(height: 10),
              Text(
                appState.translate('quote_section'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(appState.translate('vat_toggle')),
                  Switch(
                    value: _includeIva,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) {
                      setState(() => _includeIva = val);
                      _saveDraft();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                '${appState.translate('profit_margin')} ${_margin.toInt()}%',
              ),
              Slider(
                value: _margin,
                min: 0,
                max: 500,
                divisions: 50,
                activeColor: Colors.orangeAccent,
                onChanged: (val) {
                  setState(() => _margin = val);
                  _saveDraft();
                },
              ),
              const SizedBox(height: 15),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    _buildCostRow('Costo Materiales:', getMaterialsCost()),
                    _buildCostRow('Consumo Eléctrico:', getElectricityCost()),
                    _buildCostRow(
                      'Depreciación Máquinas:',
                      getDepreciationCost(),
                    ),
                    _buildCostRow(
                      '${appState.translate('preparation')} + ${appState.translate('post_processing')}:',
                      getLaborCost(),
                    ),
                    _buildCostRow('Otros Extras:', getAdditionalCostsSum()),
                    const Divider(color: Colors.white24),
                    _buildCostRow(
                      appState.translate('total_manufacturing'),
                      totalCost,
                      isBold: true,
                    ),
                    _buildCostRow(
                      '${appState.translate('profit_margin')} (${_margin.toInt()}%):',
                      salePriceBeforeIva - totalCost,
                    ),
                    if (_includeIva) ...[
                      _buildCostRow(
                        appState.translate('neto'),
                        salePriceBeforeIva,
                      ),
                      _buildCostRow(appState.translate('vat_amount'), ivaCost),
                    ],
                    const Divider(color: Colors.cyanAccent),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appState.translate('final_price'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        Text(
                          appState.format(salePrice),
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
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _saveProject,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  appState.translate('save_project'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.white : Colors.white70,
            ),
          ),
          Text(
            appState.format(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintBedModal(BuildContext context, int? indexToEdit) {
    if (appState.printers.isEmpty || appState.materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.translate('no_printers_mats'))),
      );
      return;
    }

    final bed = indexToEdit != null ? _projectPrintBeds[indexToEdit] : null;

    final nameCtrl = TextEditingController(
      text: bed?.name ?? 'Cama ${indexToEdit ?? _projectPrintBeds.length + 1}',
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
                                _projectPrintBeds.add(newBed);
                              } else {
                                _projectPrintBeds[indexToEdit] = newBed;
                              }
                            });
                            _saveDraft();
                            Navigator.pop(ctx);
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
}
