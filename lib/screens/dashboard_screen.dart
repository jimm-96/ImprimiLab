import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'printer_list_screen.dart';
import 'material_list_screen.dart';
import 'new_project_screen.dart';
import 'project_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
