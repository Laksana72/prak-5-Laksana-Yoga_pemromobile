
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_model.dart';
import '../services/api_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  // Titik awal peta: Yogyakarta
  static const LatLng _initialCenter = LatLng(
    -7.8318,
    110.3808,
  );

  List<LocationModel> _locations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  // Menampilkan pesan
  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // Mengambil data dari MockAPI
  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getLocations();

      if (!mounted) return;

      setState(() {
        _locations = data;
      });
    } catch (e) {
      _showMessage('Gagal mengambil data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Memeriksa izin dan mengambil lokasi GPS
  Future<Position?> _getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showMessage('Aktifkan GPS terlebih dahulu.');
      return null;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Izin lokasi ditolak.');
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Izin lokasi diblokir. Buka pengaturan aplikasi.');
      await Geolocator.openAppSettings();
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // Mengambil lokasi GPS dan membuka Bottom Sheet
  Future<void> _addAtCurrentLocation() async {
    final position = await _getPosition();

    if (position == null || !mounted) return;

    final point = LatLng(
      position.latitude,
      position.longitude,
    );

    _mapController.move(point, 16);

    await _showAddLocationSheet(point);
  }

  // Bottom Sheet untuk menambahkan tempat makan
  Future<void> _showAddLocationSheet(LatLng point) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rekomendasi Kuliner',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Tambahkan informasi tempat makan pilihanmu.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tempat / Menu',
                      hintText: 'Contoh: Nasi Goreng Pak Kumis',
                      prefixIcon: Icon(Icons.restaurant),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tempat wajib diisi.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'Ceritakan tentang tempat makan ini...',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Latitude: ${point.latitude.toStringAsFixed(6)}\n'
                      'Longitude: ${point.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext, false);
                          },
                          child: const Text('Batal'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(sheetContext, true);
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != true || !mounted) {
      nameController.dispose();
      descriptionController.dispose();
      return;
    }

    try {
      final success = await _apiService.addLocation(
        LocationModel(
          id: '',
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      );

      if (!mounted) return;

      if (success) {
        await _fetchLocations();

        if (!mounted) return;

        _mapController.move(point, 16);
        _showMessage('Rekomendasi berhasil disimpan!');
      } else {
        _showMessage('Gagal menyimpan data.');
      }
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  // Detail tempat ketika marker ditekan
  void _showLocationDetail(LocationModel loc) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(
                      Icons.restaurant,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      loc.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'Deskripsi Tempat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                loc.description.isEmpty
                    ? 'Belum ada deskripsi tempat.'
                    : loc.description,
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 15),

              Text(
                'Latitude: ${loc.latitude}\n'
                'Longitude: ${loc.longitude}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _mapController.move(
                      LatLng(loc.latitude, loc.longitude),
                      17,
                    );

                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Lihat di Peta'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Membuat marker setiap tempat makan
  Marker _buildMarker(LocationModel loc) {
    return Marker(
      point: LatLng(loc.latitude, loc.longitude),
      width: 150,
      height: 75,
      child: GestureDetector(
        onTap: () => _showLocationDetail(loc),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.deepOrange,
              size: 38,
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 3,
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Text(
                loc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KulinerHunt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang data',
            onPressed: _fetchLocations,
          ),
        ],
      ),

      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14,

              // Ketuk peta untuk memilih lokasi
              onTap: (tapPosition, point) {
                _showAddLocationSheet(point);
              },
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.kuliner_hunt',
              ),

              MarkerLayer(
                markers: _locations.map(_buildMarker).toList(),
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),

          if (_isLoading)
            const Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAtCurrentLocation,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Lokasi Saya'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
