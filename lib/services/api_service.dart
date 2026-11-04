import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class ApiService {
  static const String _baseUrl =
      'https://69089e042d902d0651b114ba.mockapi.io/api/v1/locations';

  // GET: mengambil daftar lokasi
  Future<List<LocationModel>> getLocations() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);

      return jsonList
          .map((e) => LocationModel.fromJson(e))
          .toList();
    }

    throw Exception(
      'Gagal mengambil data (kode ${response.statusCode}).',
    );
  }

  // POST: menyimpan rekomendasi lokasi
  Future<bool> addLocation(LocationModel model) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(model.toJson()),
    );

    return response.statusCode == 201;
  }
}