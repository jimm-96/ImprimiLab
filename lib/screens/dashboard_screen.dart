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
                                break;
                              case 'argentina':
                                localLanguage = 'es';
                                localCurrency = 'ARS';
                                taxCtrl.text = '21';
                                break;
                              case 'spain':
                                localLanguage = 'es';
                                localCurrency = 'EUR';
                                taxCtrl.text = '21';
                                break;
                              case 'mexico':
                                localLanguage = 'es';
                                localCurrency = 'MXN';
                                taxCtrl.text = '16';
                                break;
                              case 'usa':
                                localLanguage = 'en';
                                localCurrency = 'USD';
                                taxCtrl.text = '0';
                                break;
                              case 'custom':
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
                child: filteredProjects.isEmpty
                    ? Center(
                        child: Text(
                          _selectedCollectionFilter == 'all'
                              ? appState.translate('no_projects')
                              : 'No hay proyectos en esta colección.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          final cost = project.getTotalManufacturingCost(
                            appState.electricityPriceKwh,
                          );
                          final price = project.getFinalSalePrice(
                            appState.electricityPriceKwh,
                          );

                          String dateStr = project.deliveryDate != null
                              ? "${project.deliveryDate!.day}/${project.deliveryDate!.month}/${project.deliveryDate!.year}"
                              : "Sin fecha";
                          String timeStr = project.deliveryTime != null
                              ? project.deliveryTime!.format(context)
                              : "";

                          // Calcular color de contorno y estado traducido
                          Color borderColor = Colors.grey;
                          String statusText = appState.translate('own_project');

                          if (project.status == 'independiente') {
                            borderColor = Colors.cyanAccent;
                            statusText = appState.translate('independiente');
                          } else if (project.status == 'cancelado') {
                            borderColor = Colors.grey.shade600;
                            statusText = appState.translate('cancelado');
                          } else if (project.status != 'propio') {
                            statusText = appState.translate(project.status);

                            if (project.deliveryDate != null) {
                              final now = DateTime.now();
                              final deliveryMidnight = DateTime(
                                project.deliveryDate!.year,
                                project.deliveryDate!.month,
                                project.deliveryDate!.day,
                              );
                              final todayMidnight = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              final diffDays = deliveryMidnight
                                  .difference(todayMidnight)
                                  .inDays;

                              if (diffDays <= 1) {
                                borderColor = Colors.redAccent;
                              } else if (diffDays <= 3) {
                                borderColor = Colors.yellowAccent;
                              } else {
                                borderColor = Colors.greenAccent;
                              }
                            } else {
                              borderColor = Colors.greenAccent;
                            }
                          } else {
                            borderColor = Colors.grey;
                            statusText = appState.translate('own_project');
                          }

                          return Dismissible(
                            key: Key(project.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                                      builder: (_) =>
                                          ProjectDetailScreen(project: project),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (project.collectionName
                                          .trim()
                                          .isNotEmpty) ...[
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
                                      if (project.clientName
                                          .trim()
                                          .isNotEmpty) ...[
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
}
