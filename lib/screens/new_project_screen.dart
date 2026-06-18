import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../state/app_state.dart';
import '../models/project.dart';
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
  final _laborController = TextEditingController(text: '0');
  double _margin = 100.0;
  final List<Piece> _projectPieces = [];
  DateTime? _tempDeliveryDate;
  TimeOfDay? _tempDeliveryTime;
  String _priority = 'Media';
  bool _hasSanding = false;
  bool _hasPainting = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('draft_name') ?? '';
      _laborController.text = prefs.getString('draft_labor') ?? '0';
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
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_name', _nameController.text);
    await prefs.setString('draft_labor', _laborController.text);
    await prefs.setString('draft_priority', _priority);
    await prefs.setBool('draft_sanding', _hasSanding);
    await prefs.setBool('draft_painting', _hasPainting);
    await prefs.setString('draft_image', _imageController.text);
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

  void _addPieceToProject(Piece piece) {
    setState(() {
      _projectPieces.add(piece);
    });
  }

  void _saveProject() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa los campos obligatorios.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final project = Project(
      id: DateTime.now().toString(),
      name: _nameController.text,
      imagePath: _imageController.text,
      pieces: _projectPieces,
      laborCost: double.tryParse(_laborController.text) ?? 0.0,
      marginPercent: _margin,
      deliveryDate: _tempDeliveryDate,
      deliveryTime: _tempDeliveryTime,
      priority: _priority,
      hasSanding: _hasSanding,
      hasPainting: _hasPainting,
    );

    appState.addProject(project);
    _clearDraft();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double totalCost =
        _projectPieces.fold(
          0.0,
          (s, p) => s + p.getTotalCost(appState.electricityPriceKwh),
        ) +
        (double.tryParse(_laborController.text) ?? 0);
    double salePrice = totalCost * (1 + (_margin / 100));

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Proyecto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Proyecto *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
                onChanged: (_) => _saveDraft(),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: 'Evidencia fotográfica',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library, color: Colors.black),
                    label: const Text(
                      'Subir',
                      style: TextStyle(color: Colors.black),
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
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (kIsWeb && _imageController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: Text(
                      'Imagen guardada: ${_imageController.text}',
                      style: const TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              const Text(
                'Prioridad del Pedido:',
                style: TextStyle(fontSize: 16, color: Colors.cyanAccent),
              ),
              RadioGroup<String>(
                groupValue: _priority,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _priority = v);
                    _saveDraft();
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Alta'),
                        value: 'Alta',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Media'),
                        value: 'Media',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Baja'),
                        value: 'Baja',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              const Text(
                'Servicios de Post-Procesado:',
                style: TextStyle(fontSize: 16, color: Colors.cyanAccent),
              ),
              CheckboxListTile(
                title: const Text('Lijado y Limpieza de Soportes'),
                value: _hasSanding,
                onChanged: (v) {
                  setState(() => _hasSanding = v!);
                  _saveDraft();
                },
              ),
              CheckboxListTile(
                title: const Text('Pintura / Imprimación'),
                value: _hasPainting,
                onChanged: (v) {
                  setState(() => _hasPainting = v!);
                  _saveDraft();
                },
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Fecha y Hora de Entrega",
                  style: TextStyle(color: Colors.cyanAccent),
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

              const Text(
                'Piezas del Proyecto:',
                style: TextStyle(fontSize: 18, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 10),
              ..._projectPieces.map(
                (p) => Card(
                  color: const Color(0xFF334155),
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.material.name} - ${p.slicerConfig.summary}',
                    ),
                    trailing: Text(
                      '\$${p.getTotalCost(appState.electricityPriceKwh).round()}',
                    ),
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed: () => _showAddPieceModal(context),
                icon: const Icon(Icons.add_box),
                label: const Text('Agregar Pieza desde Slicer'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 30),
              const Divider(),

              const Text(
                'Ajustes Financieros:',
                style: TextStyle(fontSize: 18, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _laborController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mano de Obra / Extras (\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
                onChanged: (_) {
                  setState(() {});
                  _saveDraft();
                },
              ),
              const SizedBox(height: 20),
              Text('Margen de Ganancia: ${_margin.toInt()}%'),
              Slider(
                value: _margin,
                min: 0,
                max: 500,
                divisions: 50,
                activeColor: Colors.orangeAccent,
                onChanged: (val) => setState(() => _margin = val),
              ),

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
                        Text('\$${totalCost.round()}'),
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
                        Text(
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
                onPressed: _saveProject,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.cyanAccent,
                ),
                child: const Text(
                  'GUARDAR PROYECTO',
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
      ),
    );
  }

  void _showAddPieceModal(BuildContext context) {
    if (appState.printers.isEmpty || appState.materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes registrar al menos 1 impresora y 1 material primero.',
          ),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    final profileNameCtrl = TextEditingController(text: "Default");
    bool hasSupports = false;
    final supportTypeCtrl = TextEditingController();

    final fdmLayerCtrl = TextEditingController(text: "0.2");
    final fdmInfillCtrl = TextEditingController(text: "15");
    final fdmNozzleTempCtrl = TextEditingController(text: "210");
    final fdmBedTempCtrl = TextEditingController(text: "60");

    final resinLayerCtrl = TextEditingController(text: "0.05");
    final resinNormalExpCtrl = TextEditingController(text: "2.5");
    final resinBottomExpCtrl = TextEditingController(text: "25.0");
    final resinBottomLayersCtrl = TextEditingController(text: "6");

    Printer? selectedPrinter = appState.printers.isNotEmpty
        ? appState.printers.first
        : null;
    Material3D? selectedMaterial = appState.materials.isNotEmpty
        ? appState.materials.first
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            final isResinPrinter = selectedPrinter?.isResin ?? false;
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
                      'Datos de Laminación',
                      style: TextStyle(fontSize: 20, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de Pieza (ej. Base, Brazo)',
                      ),
                    ),
                    DropdownButtonFormField<Printer>(
                      initialValue: selectedPrinter,
                      decoration: const InputDecoration(labelText: 'Impresora'),
                      items: appState.printers
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setStateModal(() => selectedPrinter = v),
                    ),
                    DropdownButtonFormField<Material3D>(
                      initialValue: selectedMaterial,
                      decoration: const InputDecoration(labelText: 'Material'),
                      items: appState.materials
                          .map(
                            (m) =>
                                DropdownMenuItem(value: m, child: Text(m.name)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setStateModal(() => selectedMaterial = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Consumo (g o ml)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: timeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tiempo (Horas)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const Text(
                      'Configuración del Slicer',
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                    TextField(
                      controller: profileNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Perfil',
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Tiene Soportes'),
                      value: hasSupports,
                      onChanged: (val) =>
                          setStateModal(() => hasSupports = val),
                    ),
                    if (hasSupports)
                      TextField(
                        controller: supportTypeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Soporte (ej. Árbol, Normal)',
                        ),
                      ),

                    const SizedBox(height: 10),
                    if (isResinPrinter) ...[
                      const Text(
                        'Parámetros de Resina',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: resinLayerCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Capa (mm)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: resinNormalExpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Exp. Normal (s)'),
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
                              decoration: const InputDecoration(
                                  labelText: 'Exp. Base (s)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: resinBottomLayersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Capas Base'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Parámetros FDM',
                        style: TextStyle(color: Colors.lightGreenAccent),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fdmLayerCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Capa (mm)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fdmInfillCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Relleno (%)'),
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
                              decoration: const InputDecoration(
                                  labelText: 'Nozzle (°C)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fdmBedTempCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Cama (°C)'),
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
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.isEmpty ||
                                qtyCtrl.text.isEmpty ||
                                timeCtrl.text.isEmpty ||
                                selectedPrinter == null ||
                                selectedMaterial == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor, completa el nombre, material, cantidad y tiempo.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            try {
                              SlicerConfig config;
                              if (isResinPrinter) {
                                config = ResinSlicerConfig(
                                  profileName: profileNameCtrl.text,
                                  hasSupports: hasSupports,
                                  supportType: supportTypeCtrl.text,
                                  layerHeight: double.parse(
                                    resinLayerCtrl.text.replaceAll(',', '.'),
                                  ),
                                  normalExposure: double.parse(
                                    resinNormalExpCtrl.text.replaceAll(
                                        ',', '.'),
                                  ),
                                  bottomExposure: double.parse(
                                    resinBottomExpCtrl.text.replaceAll(
                                        ',', '.'),
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

                              final piece = Piece(
                                name: nameCtrl.text,
                                printer: selectedPrinter!,
                                material: selectedMaterial!,
                                quantityUsed: double.parse(
                                  qtyCtrl.text.replaceAll(',', '.'),
                                ),
                                timeHours: double.parse(
                                  timeCtrl.text.replaceAll(',', '.'),
                                ),
                                slicerConfig: config,
                              );
                              _addPieceToProject(piece);
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
                          child: const Text('Agregar Pieza'),
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
