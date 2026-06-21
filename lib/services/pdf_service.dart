import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/project.dart';
import '../state/app_state.dart';

class PdfService {
  static Future<void> generateAndShareQuote(
    Project project,
    double kwhPrice,
  ) async {
    final pdf = pw.Document();

    final cost = project.getTotalManufacturingCost(kwhPrice);
    final priceBeforeIva = project.getSuggestedSalePrice(kwhPrice);
    final iva = project.getIvaCost(kwhPrice);
    final finalPrice = project.getFinalSalePrice(kwhPrice);

    String dateStr = project.deliveryDate != null
        ? "${project.deliveryDate!.day}/${project.deliveryDate!.month}/${project.deliveryDate!.year}"
        : (appState.language == 'es' ? 'Sin fecha' : 'No date');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      appState.translate('app_title'),
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.cyan,
                      ),
                    ),
                    pw.Text(
                      appState.language == 'es'
                          ? 'COTIZACIÓN DE PROYECTO'
                          : 'PROJECT QUOTATION',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.cyan, thickness: 2),
                pw.SizedBox(height: 15),

                // Info General del Proyecto
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${appState.translate('projects')}: ${project.name}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (project.collectionName.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${appState.translate('collection')}: ${project.collectionName}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.cyan900,
                            ),
                          ),
                        ],
                        if (project.clientName.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${appState.translate('client_name')}: ${project.clientName} ${project.clientContact.trim().isNotEmpty ? "(${project.clientContact})" : ""}',
                          ),
                        ],
                        pw.SizedBox(height: 5),
                        pw.Text(
                          '${appState.translate('state')}: ${appState.translate(project.status).toUpperCase()}',
                        ),
                        if (project.status != 'propio' &&
                            project.status != 'independiente' &&
                            project.status != 'cancelado')
                          pw.Text(
                            '${appState.translate('priority').replaceAll(':', '')}: ${appState.translate(project.priority == 'Alta' ? 'urgency_red' : (project.priority == 'Media' ? 'urgency_yellow' : 'urgency_green'))}',
                          ),
                        if (project.referenceUrl.isNotEmpty)
                          pw.Text(
                            '${appState.translate('ref_url')}: ${project.referenceUrl}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '${appState.language == 'es' ? 'Fecha Emisión' : 'Issue Date'}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        ),
                        if (project.status != 'propio' &&
                            project.status != 'independiente' &&
                            project.status != 'cancelado')
                          pw.Text(
                            '${appState.language == 'es' ? 'Fecha Entrega' : 'Delivery Date'}: $dateStr',
                          ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Tabla de Camas de Impresión y Piezas
                pw.Text(
                  appState.language == 'es'
                      ? 'Camas de Impresión y Piezas'
                      : 'Print Beds & Pieces',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.cyan800,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...project.printBeds.expand((bed) {
                  final unit = bed.material.isResin ? 'ml' : 'g';
                  return [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${bed.name} (${bed.printer.name} - ${bed.material.name} ${bed.material.color})',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.cyan900,
                            ),
                          ),
                          pw.Text(
                            '${bed.printHours}h ${bed.printMinutes}m | Subtotal: ${appState.format(bed.getTotalCost(kwhPrice))}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.TableHelper.fromTextArray(
                      headers: [
                        appState.language == 'es' ? 'Pieza' : 'Piece',
                        appState.language == 'es' ? 'Cant. Base' : 'Base Qty',
                        appState.language == 'es' ? 'Merma' : 'Loss',
                        appState.language == 'es'
                            ? 'Consumo Total'
                            : 'Total Consumed',
                        appState.language == 'es'
                            ? 'Configuración Slicer'
                            : 'Slicer Config',
                      ],
                      data: bed.pieces.map((p) {
                        return [
                          p.name,
                          '${p.quantityUsed.round()}$unit',
                          p.isLossPercent
                              ? '${p.lossValue.round()}%'
                              : '${p.lossValue.round()}$unit',
                          '${p.totalMaterialUsed.round()}$unit',
                          p.slicerConfig.summary,
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 8,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.cyan800,
                      ),
                      cellAlignment: pw.Alignment.centerLeft,
                      cellStyle: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 10),
                  ];
                }).toList(),
                pw.SizedBox(height: 20),

                // Mano de Obra y Post-procesado
                pw.Text(
                  appState.translate('labor_section'),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.cyan800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: [
                    appState.language == 'es' ? 'Concepto' : 'Task',
                    appState.language == 'es' ? 'Tiempo' : 'Time',
                    appState.language == 'es'
                        ? 'Tarifa por Hora'
                        : 'Hourly Rate',
                    'Subtotal',
                  ],
                  data: [
                    [
                      appState.translate('preparation'),
                      '${project.preparationTimeMinutes} min',
                      '${appState.format(project.preparationCostPerHour)}/h',
                      appState.format(
                        ((project.preparationTimeMinutes / 60.0) *
                            project.preparationCostPerHour),
                      ),
                    ],
                    [
                      appState.translate('post_processing'),
                      '${project.postProcessingTimeMinutes} min',
                      '${appState.format(project.postProcessingCostPerHour)}/h',
                      appState.format(
                        ((project.postProcessingTimeMinutes / 60.0) *
                            project.postProcessingCostPerHour),
                      ),
                    ],
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Costos Adicionales
                if (project.additionalCosts.isNotEmpty) ...[
                  pw.Text(
                    appState.translate('additional_costs'),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.cyan800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.TableHelper.fromTextArray(
                    headers: [
                      appState.language == 'es' ? 'Descripción' : 'Description',
                      appState.language == 'es' ? 'Costo' : 'Cost',
                    ],
                    data: project.additionalCosts.map((item) {
                      return [
                        item['name'] as String,
                        appState.format((item['cost'] as num).toDouble()),
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],

                pw.Spacer(),

                // Resumen de Precios
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.cyan, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfCostRow(
                          appState.language == 'es'
                              ? 'Costo Fabricación:'
                              : 'Manufacturing Cost:',
                          cost,
                        ),
                        _buildPdfCostRow(
                          '${appState.translate('profit_margin')} (${project.marginPercent.toInt()}%):',
                          priceBeforeIva - cost,
                        ),
                        pw.Divider(color: PdfColors.grey),
                        _buildPdfCostRow(
                          appState.translate('neto'),
                          priceBeforeIva,
                        ),
                        if (project.includeIva) ...[
                          _buildPdfCostRow(
                            appState.translate('vat_amount'),
                            iva,
                          ),
                        ],
                        pw.Divider(color: PdfColors.cyan, thickness: 1.5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              appState.translate('total_sale'),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                                color: PdfColors.cyan900,
                              ),
                            ),
                            pw.Text(
                              appState.format(finalPrice),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                                color: PdfColors.green900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Cotizacion_${project.name.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Row _buildPdfCostRow(String title, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          appState.format(amount),
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
