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

  Map<String, dynamic> toJson();

  static SlicerConfig fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (type == 'fdm') {
      return FdmSlicerConfig(
        profileName: json['profileName'] ?? "Default",
        hasSupports: json['hasSupports'] ?? false,
        supportType: json['supportType'] ?? "",
        nozzleDiameter: (json['nozzleDiameter'] as num?)?.toDouble() ?? 0.4,
        layerHeight: (json['layerHeight'] as num?)?.toDouble() ?? 0.2,
        infillPercent: (json['infillPercent'] as num?)?.toDouble() ?? 15.0,
        nozzleTemp: (json['nozzleTemp'] as num?)?.toDouble() ?? 210.0,
        bedTemp: (json['bedTemp'] as num?)?.toDouble() ?? 60.0,
        speed: (json['speed'] as num?)?.toDouble() ?? 50.0,
      );
    } else {
      return ResinSlicerConfig(
        profileName: json['profileName'] ?? "Default",
        hasSupports: json['hasSupports'] ?? false,
        supportType: json['supportType'] ?? "",
        layerHeight: (json['layerHeight'] as num?)?.toDouble() ?? 0.05,
        normalExposure: (json['normalExposure'] as num?)?.toDouble() ?? 2.5,
        bottomExposure: (json['bottomExposure'] as num?)?.toDouble() ?? 25.0,
        bottomLayers: (json['bottomLayers'] as num?)?.toInt() ?? 6,
      );
    }
  }
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

  @override
  Map<String, dynamic> toJson() => {
    'type': 'fdm',
    'profileName': profileName,
    'hasSupports': hasSupports,
    'supportType': supportType,
    'nozzleDiameter': nozzleDiameter,
    'layerHeight': layerHeight,
    'infillPercent': infillPercent,
    'nozzleTemp': nozzleTemp,
    'bedTemp': bedTemp,
    'speed': speed,
  };
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

  @override
  Map<String, dynamic> toJson() => {
    'type': 'resin',
    'profileName': profileName,
    'hasSupports': hasSupports,
    'supportType': supportType,
    'layerHeight': layerHeight,
    'normalExposure': normalExposure,
    'bottomExposure': bottomExposure,
    'bottomLayers': bottomLayers,
  };
}
