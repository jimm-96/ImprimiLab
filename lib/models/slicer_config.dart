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
