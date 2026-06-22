import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'printer_list_screen.dart';
import 'material_list_screen.dart';
import 'new_project_screen.dart';
import 'project_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedCollectionFilter = 'all';

  List<String> _getCollections() {
    final list = appState.projects
        .map((p) => p.collectionName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  void _showSettingsModal(BuildContext context) {
    String localCountry = appState.country == "Chile"
        ? "chile"
        : (appState.country == "Argentina"
              ? "argentina"
              : (appState.country == "España"
                    ? "spain"
                    : (appState.country == "México"
                          ? "mexico"
                          : (appState.country == "Estados Unidos"
                                ? "usa"
                                : "custom"))));
    String localLanguage = appState.language;
    String localCurrency = appState.currency;
    final taxCtrl = TextEditingController(
      text: appState.defaultTaxRate.toString(),
    );
    final customCurrencyCtrl = TextEditingController(text: appState.currency);
    final kwhCtrl = TextEditingController(
      text: appState.electricityPriceKwh.toString(),
    );

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
                      appState.translate('settings_title'),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),

                    // Selección País
                    Text(
                      appState.translate('country'),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: localCountry,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      items: [
                        DropdownMenuItem(
                          value: 'chile',
                          child: Text('${appState.translate('chile')} 🇨🇱'),
                        ),
                        DropdownMenuItem(
                          value: 'argentina',
                          child: Text(
                            '${appState.translate('argentina')} 🇦🇷',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'spain',
                          child: Text('${appState.translate('spain')} 🇪🇸'),
                        ),
                        DropdownMenuItem(
                          value: 'mexico',
                          child: Text('${appState.translate('mexico')} 🇲🇽'),
                        ),
                        DropdownMenuItem(
                          value: 'usa',
                          child: Text('${appState.translate('usa')} 🇺🇸'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('${appState.translate('custom')} 🌐'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateModal(() {
                            localCountry = val;
                            switch (val) {
                              case 'chile':
                                localLanguage = 'es';
                                localCurrency = 'CLP';
                                taxCtrl.text = '19';
                                kwhCtrl.text = '150';
                                break;
                              case 'argentina':
                                localLanguage = 'es';
                                localCurrency = 'ARS';
                                taxCtrl.text = '21';
                                kwhCtrl.text = '60';
                                break;
                              case 'spain':
                                localLanguage = 'es';
                                localCurrency = 'EUR';
                                taxCtrl.text = '21';
                                kwhCtrl.text = '0.22';
                                break;
                              case 'mexico':
                                localLanguage = 'es';
                                localCurrency = 'MXN';
                                taxCtrl.text = '16';
                                kwhCtrl.text = '2.0';
                                break;
                              case 'usa':
                                localLanguage = 'en';
                                localCurrency = 'USD';
                                taxCtrl.text = '0';
                                kwhCtrl.text = '0.16';
                                break;
                              case 'custom':
                                kwhCtrl.text = '0.15';
                                break;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Selección Idioma
                    Text(
                      appState.translate('language'),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: localLanguage,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateModal(() => localLanguage = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Selección Moneda
                    Text(
                      appState.translate('currency'),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value:
                          [
                            'CLP',
                            'ARS',
                            'USD',
                            'EUR',
                            'MXN',
                          ].contains(localCurrency)
                          ? localCurrency
                          : 'CUSTOM',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      items: [
                        const DropdownMenuItem(
                          value: 'CLP',
                          child: Text('CLP (\$)'),
                        ),
                        const DropdownMenuItem(
                          value: 'ARS',
                          child: Text('ARS (\$)'),
                        ),
                        const DropdownMenuItem(
                          value: 'MXN',
                          child: Text('MXN (\$)'),
                        ),
                        const DropdownMenuItem(
                          value: 'USD',
                          child: Text('USD (\$)'),
                        ),
                        const DropdownMenuItem(
                          value: 'EUR',
                          child: Text('EUR (€)'),
                        ),
                        const DropdownMenuItem(
                          value: 'CUSTOM',
                          child: Text('Otro (Código)'),
                        ),
                      ],
                      onChanged: localCountry == 'custom'
                          ? (val) {
                              if (val != null) {
                                setStateModal(() => localCurrency = val);
                              }
                            }
                          : null,
                    ),
                    if (localCountry == 'custom' &&
                        (localCurrency == 'CUSTOM' ||
                            ![
                              'CLP',
                              'ARS',
                              'USD',
                              'EUR',
                              'MXN',
                            ].contains(localCurrency))) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: customCurrencyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código de Divisa (ej. ARS)',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Impuesto por defecto
                    Text(
                      appState.translate('default_tax'),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: taxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Costo de Electricidad por kWh',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: kwhCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                            final String finalCurrency =
                                localCountry == 'custom' &&
                                    (localCurrency == 'CUSTOM' ||
                                        ![
                                          'CLP',
                                          'ARS',
                                          'USD',
                                          'EUR',
                                          'MXN',
                                        ].contains(localCurrency))
                                ? customCurrencyCtrl.text.toUpperCase().trim()
                                : localCurrency;
                            final double taxVal =
                                double.tryParse(taxCtrl.text) ?? 0.0;
                            final double kwhVal =
                                double.tryParse(kwhCtrl.text.replaceAll(',', '.')) ?? 0.15;

                            String countryName = "Chile";
                            switch (localCountry) {
                              case 'chile':
                                countryName = "Chile";
                                break;
                              case 'argentina':
                                countryName = "Argentina";
                                break;
                              case 'spain':
                                countryName = "España";
                                break;
                              case 'mexico':
                                countryName = "México";
                                break;
                              case 'usa':
                                countryName = "Estados Unidos";
                                break;
                              case 'custom':
                                countryName = "Personalizado";
                                break;
                            }

                            appState.updateSettings(
                              countryVal: countryName,
                              languageVal: localLanguage,
                              currencyVal: finalCurrency,
                              taxRateVal: taxVal,
                              electricityPriceKwhVal: kwhVal,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(appState.translate('save_settings')),
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
        title: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => Text(
            appState.translate('app_title'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            tooltip: appState.translate('settings'),
            onPressed: () => _showSettingsModal(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          final collections = _getCollections();
          if (_selectedCollectionFilter != 'all' &&
              !collections.contains(_selectedCollectionFilter)) {
            _selectedCollectionFilter = 'all';
          }

          final filteredProjects = _selectedCollectionFilter == 'all'
              ? appState.projects
              : appState.projects
                    .where(
                      (p) =>
                          p.collectionName.trim() == _selectedCollectionFilter,
                    )
                    .toList();

          final List<DashboardItem> dashboardItems = [];
          final looseProjects = filteredProjects
              .where((p) => p.collectionName.trim().isEmpty)
              .toList();

          final Map<String, List<Project>> grouped = {};
          for (var p in filteredProjects) {
            final colName = p.collectionName.trim();
            if (colName.isNotEmpty) {
              grouped.putIfAbsent(colName, () => []).add(p);
            }
          }

          for (var p in looseProjects) {
            dashboardItems.add(DashboardItem.project(p));
          }

          grouped.forEach((colName, projs) {
            dashboardItems.add(DashboardItem.collection(colName, projs));
          });

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
                      label: Text(appState.translate('printers')),
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
                      label: Text(appState.translate('materials')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              if (appState.projects.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCollectionFilter,
                    decoration: InputDecoration(
                      labelText: appState.translate('collection'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    dropdownColor: const Color(0xFF1E293B),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(appState.translate('all_collections')),
                      ),
                      ...collections.map(
                        (col) => DropdownMenuItem(value: col, child: Text(col)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCollectionFilter = val);
                      }
                    },
                  ),
                ),
              Expanded(
                child: dashboardItems.isEmpty
                    ? Center(
                        child: Text(
                          _selectedCollectionFilter == 'all'
                              ? appState.translate('no_projects')
                              : 'No hay proyectos en esta colección.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: dashboardItems.length,
                        itemBuilder: (context, index) {
                          final item = dashboardItems[index];
                          if (item.isProject) {
                            return _buildProjectCard(context, item.project!);
                          } else {
                            return _buildCollectionCard(
                              context,
                              item.collectionName!,
                              item.groupedProjects!,
                            );
                          }
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: appState,
        builder: (context, _) => FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewProjectScreen()),
          ),
          icon: const Icon(Icons.add, color: Colors.black),
          label: Text(
            appState.translate('new_project'),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.cyanAccent,
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    final cost = project.getTotalManufacturingCost(appState.electricityPriceKwh);
    final price = project.getFinalSalePrice(appState.electricityPriceKwh);

    String dateStr = project.deliveryDate != null
        ? "${project.deliveryDate!.day}/${project.deliveryDate!.month}/${project.deliveryDate!.year}"
        : "Sin fecha";
    String timeStr = project.deliveryTime != null
        ? project.deliveryTime!.format(context)
        : "";

    Color borderColor = Colors.grey;
    String statusText = appState.translate('own_project');

    switch (project.status) {
      case 'pendiente':
        borderColor = Colors.greenAccent;
        statusText = appState.translate('pendiente');
        break;
      case 'enProceso':
        borderColor = Colors.yellowAccent;
        statusText = appState.translate('enProceso');
        break;
      case 'terminado':
        borderColor = Colors.redAccent;
        statusText = appState.translate('terminado');
        break;
      case 'propio':
        borderColor = Colors.grey;
        statusText = appState.translate('own_project');
        break;
      case 'independiente':
        borderColor = Colors.cyanAccent;
        statusText = appState.translate('independiente');
        break;
      case 'cancelado':
        borderColor = Colors.grey.shade600;
        statusText = appState.translate('cancelado');
        break;
      default:
        borderColor = Colors.grey;
        statusText = project.status;
    }

    return Dismissible(
      key: Key(project.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        appState.deleteProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appState.translate('project_deleted')}: "${project.name}"',
            ),
            action: SnackBarAction(
              label: appState.translate('undo'),
              onPressed: () {
                appState.addProject(project);
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: 2.0,
          ),
        ),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(project: project),
              ),
            );
          },
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: borderColor == Colors.grey
                        ? Colors.white70
                        : borderColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camas: ${project.printBeds.length} | ${appState.translate('pieces')}: ${project.printBeds.fold(0, (sum, b) => sum + b.pieces.length)} | ${appState.translate('cost_prod')}: ${appState.format(cost)}',
                  style: const TextStyle(height: 1.3),
                ),
                if (project.status != 'independiente' &&
                    project.status != 'propio' &&
                    project.status != 'cancelado')
                  Text(
                    '${appState.translate('delivery')}: $dateStr $timeStr',
                    style: const TextStyle(height: 1.3),
                  ),
                if (project.collectionName.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_open,
                        size: 14,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project.collectionName,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (project.clientName.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.clientName}${project.clientContact.trim().isNotEmpty ? " (${project.clientContact})" : ""}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                appState.translate('suggested_sale'),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appState.format(price),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionCard(BuildContext context, String collectionName, List<Project> projects) {
    final totalPrice = projects.fold(0.0, (sum, p) => sum + p.getFinalSalePrice(appState.electricityPriceKwh));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Colors.cyanAccent,
          width: 2.0,
        ),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.folder_open, color: Colors.cyanAccent),
        title: Text(
          collectionName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Colección | ${projects.length} proyectos | Venta Total: ${appState.format(totalPrice)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        iconColor: Colors.cyanAccent,
        collapsedIconColor: Colors.cyanAccent,
        children: projects.map((project) {
          final cost = project.getTotalManufacturingCost(appState.electricityPriceKwh);
          final price = project.getFinalSalePrice(appState.electricityPriceKwh);

          Color statusColor = Colors.grey;
          switch (project.status) {
            case 'pendiente': statusColor = Colors.greenAccent; break;
            case 'enProceso': statusColor = Colors.yellowAccent; break;
            case 'terminado': statusColor = Colors.redAccent; break;
            case 'propio': statusColor = Colors.grey; break;
            case 'independiente': statusColor = Colors.cyanAccent; break;
            case 'cancelado': statusColor = Colors.grey.shade600; break;
          }

          return Dismissible(
            key: Key(project.id),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              color: Colors.redAccent.withOpacity(0.8),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              appState.deleteProject(project);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${appState.translate('project_deleted')}: "${project.name}"',
                  ),
                  action: SnackBarAction(
                    label: appState.translate('undo'),
                    onPressed: () {
                      appState.addProject(project);
                    },
                  ),
                ),
              );
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                project.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                'Estado: ${appState.translate(project.status)} | Costo: ${appState.format(cost)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                appState.format(price),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: statusColor,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(project: project),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DashboardItem {
  final Project? project;
  final String? collectionName;
  final List<Project>? groupedProjects;

  DashboardItem.project(this.project)
      : collectionName = null,
        groupedProjects = null;

  DashboardItem.collection(this.collectionName, this.groupedProjects)
      : project = null;

  bool get isProject => project != null;
  bool get isCollection => collectionName != null;
}
