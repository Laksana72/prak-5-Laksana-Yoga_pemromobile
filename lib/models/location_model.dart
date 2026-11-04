
class LocationModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Warung Tanpa Nama',
      description: json['description'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
  }
}
