import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class EditAddressPage extends StatefulWidget {
  const EditAddressPage({super.key});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  String _selectedTag = 'Home'; // 'Home' or 'Work'

  // Map & Location State
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(3.215597, 101.728109); // Default Coords from Practical

  bool _permissionGranted = false;
  bool _gpsEnabled = false;
  bool _trackingEnabled = false;
  StreamSubscription<LocationData>? _subscription;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    checkStatus().then((_) {
      if (_gpsEnabled && _permissionGranted) {
        startTracking();
      }
    });
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  // --- LOCATION TRACKING LOGIC ---
  Future<bool> isPermissionGranted() async => await handler.Permission.locationWhenInUse.isGranted;
  Future<bool> isGpsEnabled() async => await handler.Permission.location.serviceStatus.isEnabled;

  Future<void> checkStatus() async {
    bool permissionGranted = await isPermissionGranted();
    bool gpsEnabled = await isGpsEnabled();
    if (mounted) setState(() { _permissionGranted = permissionGranted; _gpsEnabled = gpsEnabled; });
  }

  Future<void> requestEnableGps() async {
    if (_gpsEnabled) return;
    bool gpsEnabled = await _location.requestService();
    if (mounted) setState(() => _gpsEnabled = gpsEnabled);
  }

  Future<void> requestLocationPermission() async {
    var permissionStatus = await handler.Permission.locationWhenInUse.request();
    if (mounted) setState(() => _permissionGranted = permissionStatus.isGranted);
  }

  Future<void> startTracking() async {
    if (!await isGpsEnabled()) await requestEnableGps();
    if (!await isPermissionGranted()) await requestLocationPermission();

    if (await isGpsEnabled() && await isPermissionGranted()) {
      _subscription = _location.onLocationChanged.listen((LocationData data) {
        if (data.latitude != null && data.longitude != null) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(data.latitude!, data.longitude!);
              _trackingEnabled = true;
            });
            _mapController.move(_currentLocation, 18.0);
          }
        }
      });
    }
  }

  void stopTracking() {
    _subscription?.cancel();
    if (mounted) setState(() => _trackingEnabled = false);
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Address', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map View with OpenStreetMap
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        maxZoom: 20,
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.fooddeliveryapp',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: Theme.of(context).cardColor,
                      elevation: 4,
                      onPressed: () async {
                        if (_trackingEnabled) stopTracking();
                        else await startTracking();
                      },
                      child: Icon(
                        _trackingEnabled ? Icons.my_location : Icons.location_searching,
                        color: _trackingEnabled ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Fields
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTextField(context, 'Building name', 'ABC Enterprise')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(context, 'Floor/Unit', '123')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(context, 'Street', 'Jalan ABC, Taman Setapak'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(context, 'Postal Code', '53000')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(context, 'State', 'Kuala Lumpur')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(context, 'Delivery Instruction', 'E.g. Leave at lobby...', isOptional: true, maxLines: 3),

                    const SizedBox(height: 24),
                    const Text('Add a tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTagButton(context, 'Home', Icons.home),
                        const SizedBox(width: 16),
                        _buildTagButton(context, 'Work', Icons.work),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Actions (Consistent Pill Buttons)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text('Save Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text('Cancel', style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String hint, {bool isOptional = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (isOptional)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('(Optional)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagButton(BuildContext context, String label, IconData icon) {
    final isSelected = _selectedTag == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTag = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 2
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.orange : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.orange : Theme.of(context).textTheme.bodyLarge?.color,
            )),
          ],
        ),
      ),
    );
  }
}