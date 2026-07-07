import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/slicer_config.dart';
import '../state/app_state.dart';

class PieceModal extends StatefulWidget {
  final Piece? piece;
  final bool isResin;
  final Function(Piece) onSave;

  const PieceModal({
    super.key,
    this.piece,
    required this.isResin,
    required this.onSave,
  });

  @override
  State<PieceModal> createState() => _PieceModalState();
}

class _PieceModalState extends State<PieceModal> {
  late TextEditingController nameCtrl;
  late TextEditingController qtyCtrl;
  late TextEditingController lossValueCtrl;
  late TextEditingController profileNameCtrl;
  late TextEditingController supportTypeCtrl;

  late bool hasSupports;
  late bool isLossPercent;

  // FDM Controllers
  late TextEditingController fdmLayerCtrl;
  late TextEditingController fdmInfillCtrl;
  late TextEditingController fdmNozzleTempCtrl;
  late TextEditingController fdmBedTempCtrl;

  // Resin Controllers
  late TextEditingController resinLayerCtrl;
  late TextEditingController resinNormalExpCtrl;
  late TextEditingController resinBottomExpCtrl;
  late TextEditingController resinBottomLayersCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.piece;

    nameCtrl = TextEditingController(text: p?.name ?? '');
    qtyCtrl = TextEditingController(text: p?.quantityUsed.toString() ?? '');
    lossValueCtrl = TextEditingController(text: p?.lossValue.toString() ?? '0');
    profileNameCtrl = TextEditingController(text: p?.slicerConfig.profileName ?? "Default");

    hasSupports = p?.slicerConfig.hasSupports ?? false;
    supportTypeCtrl = TextEditingController(text: p?.slicerConfig.supportType ?? '');

    isLossPercent = p?.isLossPercent ?? true;

    // FDM Defaults
    fdmLayerCtrl = TextEditingController(
      text: p?.slicerConfig is FdmSlicerConfig
          ? (p!.slicerConfig as FdmSlicerConfig).layerHeight.toString()
          : "0.2",
    );
    fdmInfillCtrl = TextEditingController(
      text: p?.slicerConfig is FdmSlicerConfig
          ? (p!.slicerConfig as FdmSlicerConfig).infillPercent.toString()
          : "15",
    );
    fdmNozzleTempCtrl = TextEditingController(
      text: p?.slicerConfig is FdmSlicerConfig
          ? (p!.slicerConfig as FdmSlicerConfig).nozzleTemp.toString()
          : "210",
    );
    fdmBedTempCtrl = TextEditingController(
      text: p?.slicerConfig is FdmSlicerConfig
          ? (p!.slicerConfig as FdmSlicerConfig).bedTemp.toString()
          : "60",
    );

    // Resin Defaults
    resinLayerCtrl = TextEditingController(
      text: p?.slicerConfig is ResinSlicerConfig
          ? (p!.slicerConfig as ResinSlicerConfig).layerHeight.toString()
          : "0.05",
    );
    resinNormalExpCtrl = TextEditingController(
      text: p?.slicerConfig is ResinSlicerConfig
          ? (p!.slicerConfig as ResinSlicerConfig).normalExposure.toString()
          : "2.5",
    );
    resinBottomExpCtrl = TextEditingController(
      text: p?.slicerConfig is ResinSlicerConfig
          ? (p!.slicerConfig as ResinSlicerConfig).bottomExposure.toString()
          : "25.0",
    );
    resinBottomLayersCtrl = TextEditingController(
      text: p?.slicerConfig is ResinSlicerConfig
          ? (p!.slicerConfig as ResinSlicerConfig).bottomLayers.toString()
          : "6",
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    lossValueCtrl.dispose();
    profileNameCtrl.dispose();
    supportTypeCtrl.dispose();
    fdmLayerCtrl.dispose();
    fdmInfillCtrl.dispose();
    fdmNozzleTempCtrl.dispose();
    fdmBedTempCtrl.dispose();
    resinLayerCtrl.dispose();
    resinNormalExpCtrl.dispose();
    resinBottomExpCtrl.dispose();
    resinBottomLayersCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (nameCtrl.text.isEmpty || qtyCtrl.text.isEmpty) return;

    try {
      SlicerConfig config;
      if (widget.isResin) {
        config = ResinSlicerConfig(
          profileName: profileNameCtrl.text,
          hasSupports: hasSupports,
          supportType: supportTypeCtrl.text,
          layerHeight: double.parse(resinLayerCtrl.text.replaceAll(',', '.')),
          normalExposure: double.parse(resinNormalExpCtrl.text.replaceAll(',', '.')),
          bottomExposure: double.parse(resinBottomExpCtrl.text.replaceAll(',', '.')),
          bottomLayers: int.parse(resinBottomLayersCtrl.text),
        );
      } else {
        config = FdmSlicerConfig(
          profileName: profileNameCtrl.text,
          hasSupports: hasSupports,
          supportType: supportTypeCtrl.text,
          layerHeight: double.parse(fdmLayerCtrl.text.replaceAll(',', '.')),
          infillPercent: double.parse(fdmInfillCtrl.text.replaceAll(',', '.')),
          nozzleTemp: double.parse(fdmNozzleTempCtrl.text.replaceAll(',', '.')),
          bedTemp: double.parse(fdmBedTempCtrl.text.replaceAll(',', '.')),
        );
      }

      final updatedPiece = Piece(
        name: nameCtrl.text,
        quantityUsed: double.parse(qtyCtrl.text.replaceAll(',', '.')),
        isLossPercent: isLossPercent,
        lossValue: double.parse(lossValueCtrl.text.replaceAll(',', '.')),
        slicerConfig: config,
      );

      widget.onSave(updatedPiece);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.translate('invalid_number'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.isResin ? 'ml' : 'g';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              widget.piece == null
                  ? 'Añadir Objeto a la Cama'
                  : 'Editar Objeto en la Cama',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
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
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${appState.translate('consumption_base')} ($unit)',
              ),
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
                        child: Text('Fijo ($unit)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => isLossPercent = val);
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
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
              onChanged: (val) => setState(() => hasSupports = val),
            ),
            if (hasSupports)
              TextField(
                controller: supportTypeCtrl,
                decoration: InputDecoration(
                  labelText: appState.translate('support_type'),
                ),
              ),
            const SizedBox(height: 10),
            if (widget.isResin) ...[
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    appState.translate('cancel'),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(appState.translate('save')),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
