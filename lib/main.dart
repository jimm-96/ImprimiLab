import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:shared_preferences/shared_preferences.dart'; // Para el guardado local
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const ImpriLabApp());
}

// ==========================================
// 1. MODELOS DE DATOS Y LÓGICA DE NEGOCIO
// ==========================================

class Printer {
  final String id;
  final String name;
  final bool isResin;
  final double powerW;
  final double cost;
  final double lifespanH;
  final DateTime? purchaseDate;

  Printer({
    required this.id,
    required this.name,
    required this.isResin,
    required this.powerW,
    required this.cost,
    required this.lifespanH,
    this.purchaseDate,
  });
}

class Material3D {
  final String id;
  final String name;
  final String color;
  final bool isResin;
  final double cost;
  final double totalQuantity; // en gramos o ml
  final DateTime? openDate;

  Material3D({
    required this.id,
    required this.name,
    this.color = "Desconocido",
    required this.isResin,
    required this.cost,
    required this.totalQuantity,
    this.openDate,
  });

  double get costPerUnit => totalQuantity > 0 ? cost / totalQuantity : 0.0;
}

abstract class SlicerConfig {
  String profileName;
  bool hasSupports;
  String supportType;

  SlicerConfig({
    this.profileName = "Default",
    this.hasSupports = false,
    this.supportType = "",
  });

  String get summary;
}

class FdmSlicerConfig extends SlicerConfig {
  double nozzleDiameter;
  double layerHeight;
  double infillPercent;
  double nozzleTemp;
  double bedTemp;
  double speed;

  FdmSlicerConfig({
    super.profileName,
    super.hasSupports,
    super.supportType,
    this.nozzleDiameter = 0.4,
    this.layerHeight = 0.2,
    this.infillPercent = 15,
    this.nozzleTemp = 210,
    this.bedTemp = 60,
    this.speed = 50,
  });

  @override
  String get summary =>
      "$profileName | Capa: ${layerHeight}mm, Relleno: $infillPercent%, Nozzle: $nozzleTemp°C, Cama: $bedTemp°C${hasSupports ? ' | Soportes: $supportType' : ''}";
}

class ResinSlicerConfig extends SlicerConfig {
  double layerHeight;
  double normalExposure;
  double bottomExposure;
  int bottomLayers;

  ResinSlicerConfig({
    super.profileName,
    super.hasSupports,
    super.supportType,
    this.layerHeight = 0.05,
    this.normalExposure = 2.5,
    this.bottomExposure = 25.0,
    this.bottomLayers = 6,
  });

  @override
  String get summary =>
      "$profileName | Capa: ${layerHeight}mm, Exp: ${normalExposure}s, Base: ${bottomExposure}s ($bottomLayers capas)${hasSupports ? ' | Soportes: $supportType' : ''}";
}

class Piece {
  final String name;
  final Printer printer;
  final Material3D material;
  final double quantityUsed; // gramos o ml
  final double timeHours;
  final SlicerConfig slicerConfig;

  Piece({
    required this.name,
    required this.printer,
    required this.material,
    required this.quantityUsed,
    required this.timeHours,
    required this.slicerConfig,
  });

  double calculateMaterialCost() => quantityUsed * material.costPerUnit;
  double calculateElectricityCost(double kwhPrice) =>
      (printer.powerW / 1000) * timeHours * kwhPrice;
  double calculateDepreciation() => printer.lifespanH > 0
      ? (printer.cost / printer.lifespanH) * timeHours
      : 0.0;

  double getTotalCost(double kwhPrice) =>
      calculateMaterialCost() +
      calculateElectricityCost(kwhPrice) +
      calculateDepreciation();
}

class Project {
  final String id;
  String name;
  String imagePath;
  List<Piece> pieces;
  double laborCost;
  double marginPercent;
  String notes;
  DateTime? deliveryDate;
  TimeOfDay? deliveryTime;
  String priority;
  bool hasSanding;
  bool hasPainting;

  Project({
    required this.id,
    required this.name,
    this.imagePath = "",
    this.pieces = const [],
    this.laborCost = 0.0,
    this.marginPercent = 100.0,
    this.notes = "",
    this.deliveryDate,
    this.deliveryTime,
    this.priority = 'Media',
    this.hasSanding = false,
    this.hasPainting = false, // Inicializados
  });

  double getTotalManufacturingCost(double kwhPrice) {
    double total = pieces.fold(
      0,
      (sum, piece) => sum + piece.getTotalCost(kwhPrice),
    );
    return total + laborCost;
  }

  double getSuggestedSalePrice(double kwhPrice) {
    return getTotalManufacturingCost(kwhPrice) * (1 + (marginPercent / 100));
  }
}

// ==========================================
// 2. GESTIÓN DE ESTADO (ChangeNotifier)
// ==========================================

class AppState extends ChangeNotifier {
  double electricityPriceKwh =
      150.0; // Precio por defecto del kWh en pesos chilenos

  // Datos semilla pre-cargados para pruebas inmediatas
  List<Printer> printers = [
    Printer(
      id: 'p1',
      name: 'Halot Mage S 14K',
      isResin: true,
      powerW: 100,
      cost: 450000,
      lifespanH: 2000,
      purchaseDate: DateTime(2023, 10, 1),
    ),
    Printer(
      id: 'p2',
      name: 'BambuLab A1',
      isResin: false,
      powerW: 350,
      cost: 300000,
      lifespanH: 5000,
      purchaseDate: DateTime(2024, 1, 15),
    ),
  ];

  List<Material3D> materials = [
    Material3D(
      id: 'm1',
      name: 'Anycubic Basic',
      color: 'Negra',
      isResin: true,
      cost: 30000,
      totalQuantity: 1000,
      openDate: DateTime(2024, 4, 1),
    ),
    Material3D(
      id: 'm2',
      name: 'eSun PLA+',
      color: 'Gris',
      isResin: false,
      cost: 18000,
      totalQuantity: 1000,
      openDate: DateTime.now(),
    ),
  ];

  List<Project> projects = [];

  void addProject(Project project) {
    projects.add(project);
    notifyListeners();
  }

  void addPrinter(Printer printer) {
    printers.add(printer);
    notifyListeners();
  }

  void addMaterial(Material3D material) {
    materials.add(material);
    notifyListeners();
  }

  void updateProject() {
    notifyListeners();
  }
}

// ==========================================
// 3. INTERFAZ DE USUARIO (UI)
// ==========================================

class ImpriLabApp extends StatelessWidget {
  const ImpriLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImpriLab',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.cyanAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.orangeAccent,
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// Instancia global simple para el MVP
final appState = AppState();

// --- PANTALLA PRINCIPAL ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty ||
                            powerCtrl.text.isEmpty ||
                            costCtrl.text.isEmpty ||
                            lifeCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Comprueba que el nombre, consumo, costo y vida útil estén llenos.',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
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
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty ||
                            colorCtrl.text.isEmpty ||
                            costCtrl.text.isEmpty ||
                            qtyCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Por favor llena todos los campos del material (nombre, color, costo, cantidad).',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
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
          'ImpriLab',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrinterListScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Impresoras'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MaterialListScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.water_drop, size: 18),
                      label: const Text('Materiales'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: appState.projects.isEmpty
                    ? const Center(
                        child: Text("No hay proyectos. ¡Crea el primero!"),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: appState.projects.length,
                        itemBuilder: (context, index) {
                          final project = appState.projects[index];
                          final cost = project.getTotalManufacturingCost(
                            appState.electricityPriceKwh,
                          );
                          final price = project.getSuggestedSalePrice(
                            appState.electricityPriceKwh,
                          );

                          String dateStr = project.deliveryDate != null
                              ? "${project.deliveryDate!.day}/${project.deliveryDate!.month}/${project.deliveryDate!.year}"
                              : "Sin fecha";
                          String timeStr = project.deliveryTime != null
                              ? project.deliveryTime!.format(context)
                              : "";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProjectDetailScreen(project: project),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                project.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Piezas: ${project.pieces.length} | Costo: \$${cost.round()}\nEntrega: $dateStr $timeStr',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Venta Sugerida',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '\$${price.round()}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewProjectScreen()),
        ),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Nuevo Proyecto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.cyanAccent,
      ),
    );
  }
}

// --- FORMULARIO DE PROYECTO Y PIEZAS ---
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
    _loadDraft(); // Carga el borrador al iniciar la pantalla
  }

  // --- LÓGICA DE PERSISTENCIA (SHARED PREFERENCES) y CAMARA ---
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
      setState(() {
        _imageController.text = pickedFile.path;
        if (!kIsWeb) {
          _selectedImage = File(pickedFile.path);
        }
      });
      _saveDraft();
    }
  }
  // ----------------------------------------------------

  void _addPieceToProject(Piece piece) {
    setState(() {
      _projectPieces.add(piece);
    });
  }

  void _saveProject() {
    // Validación del Formulario
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
        // Se envuelve el Column en un widget Form
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TextFormField con validación obligatoria
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

              // UI para subir la imagen de referencia
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: 'Evidencia fotográfica',
                        border: OutlineInputBorder(),
                      ),
                      readOnly:
                          true, // El usuario no escribe aquí, usa el botón
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
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              const Text(
                'Prioridad del Pedido:',
                style: TextStyle(fontSize: 16, color: Colors.cyanAccent),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Alta'),
                      value: 'Alta',
                      groupValue: _priority,
                      onChanged: (v) {
                        setState(() => _priority = v!);
                        _saveDraft();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Media'),
                      value: 'Media',
                      groupValue: _priority,
                      onChanged: (v) {
                        setState(() => _priority = v!);
                        _saveDraft();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Baja'),
                      value: 'Baja',
                      groupValue: _priority,
                      onChanged: (v) {
                        setState(() => _priority = v!);
                        _saveDraft();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
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
              // FormField para números
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
                onPressed:
                    _saveProject, // Ahora dispara la validación del _formKey primero
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

  // --- MODAL PARA AGREGAR UNA PIEZA (Datos del Slicer) ---
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

    // Shared Slicer Config
    final profileNameCtrl = TextEditingController(text: "Default");
    bool hasSupports = false;
    final supportTypeCtrl = TextEditingController();

    // FDM Controllers
    final fdmLayerCtrl = TextEditingController(text: "0.2");
    final fdmInfillCtrl = TextEditingController(text: "15");
    final fdmNozzleTempCtrl = TextEditingController(text: "210");
    final fdmBedTempCtrl = TextEditingController(text: "60");

    // Resin Controllers
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
                                labelText: 'Capa (mm)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: resinNormalExpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Exp. Normal (s)',
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
                              decoration: const InputDecoration(
                                labelText: 'Exp. Base (s)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: resinBottomLayersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Capas Base',
                              ),
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
                                labelText: 'Capa (mm)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fdmInfillCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Relleno (%)',
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
                              decoration: const InputDecoration(
                                labelText: 'Nozzle (°C)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: fdmBedTempCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cama (°C)',
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

// --- PANTALLA DE DETALLE / EDICIÓN ---
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
          // --- NUEVO: BOTÓN DE COPIAR AL PORTAPAPELES ---
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar Resumen',
            onPressed: () {
              String resumen =
                  '''
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
                Navigator.pop(context); // retroceso después de guardar
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

// --- PANTALLA LISTA DE IMPRESORAS ---
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
                  '${printer.isResin ? "Resina" : "FDM"} - ${printer.powerW}W - \$${printer.cost}',
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

// --- PANTALLA LISTA DE MATERIALES ---
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
                leading: Icon(Icons.circle, color: Colors.white),
                title: Text(
                  '${material.name} - ${material.color}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${material.isResin ? "Resina" : "Filamento"} - ${material.totalQuantity}g/ml - \$${material.cost}',
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
