class GeoJson {
  final String type = 'FeatureCollection';
  final List<Feature> features = [];

  Map<String, dynamic> toMap() {
    return {"type": type, "features": features.map((e) => e.toMap()).toList()};
  }
}

class Feature {
  final String type = "Feature";
  Map<String, dynamic>? properties = {};
  Map<String, dynamic>? geometry = {};

  Feature({this.properties, this.geometry});
  factory Feature.fromMap(Map<String, dynamic> data) {
    return Feature(properties: data['properties'], geometry: data['geometry']);
  }

  Map<String, dynamic> toMap() {
    return {"type": type, "properties": properties, "geometry": geometry};
  }
}
