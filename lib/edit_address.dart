import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAddressPage extends StatefulWidget {
  const EditAddressPage({super.key});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  String _selectedTag = 'Home'; // 'Home' or 'Work'
  bool _isSaving = false; // Tracks saving state for the button

  // Map & Location State
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(3.215597, 101.728109); // Default Coords from Practical

  bool _permissionGranted = false;
  bool _gpsEnabled = false;
  bool _trackingEnabled = false;
  bool _hasAutofilled = false; // Tracks if we already autofilled to prevent overriding user edits
  StreamSubscription<LocationData>? _subscription;
  final Location _location = Location();

  // Text Controllers for Autofill & Saving
  final TextEditingController _buildingCtrl = TextEditingController();
  final TextEditingController _floorCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _postalCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _instructionCtrl = TextEditingController();

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
    _buildingCtrl.dispose();
    _floorCtrl.dispose();
    _streetCtrl.dispose();
    _postalCtrl.dispose();
    _stateCtrl.dispose();
    _instructionCtrl.dispose();
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

      // 1. Immediately fetch current location (fixes issue where device is stationary)
      try {
        // Added a timeout in case the emulator's location service is hanging
        LocationData currentData = await _location.getLocation().timeout(const Duration(seconds: 10));
        if (currentData.latitude != null && currentData.longitude != null) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(currentData.latitude!, currentData.longitude!);
            });
            _mapController.move(_currentLocation, 18.0);

            if (!_hasAutofilled) {
              await _getAddressFromLatLng(currentData.latitude!, currentData.longitude!);
              _hasAutofilled = true;
            }
          }
        }
      } catch (e) {
        debugPrint("Error getting initial location: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to get GPS location. Are you on an emulator without a mock location set?'),
                backgroundColor: Colors.orange,
              )
          );
        }
      }

      // 2. Then listen for future movements
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

      if (mounted) setState(() => _trackingEnabled = true);
    }
  }

  void stopTracking() {
    _subscription?.cancel();
    if (mounted) setState(() => _trackingEnabled = false);
  }

  // --- REVERSE GEOCODING FOR AUTOFILL ---
  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];

        if (mounted) {
          setState(() {
            _buildingCtrl.text = place.name ?? '';

            // Better fallback logic for empty street fields
            List<String> streetParts = [];
            if (place.street != null && place.street!.isNotEmpty) streetParts.add(place.street!);
            if (place.subLocality != null && place.subLocality!.isNotEmpty) streetParts.add(place.subLocality!);
            if (place.locality != null && place.locality!.isNotEmpty) streetParts.add(place.locality!);

            _streetCtrl.text = streetParts.join(', ');
            _postalCtrl.text = place.postalCode ?? '';
            _stateCtrl.text = place.administrativeArea ?? '';
          });

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address autofilled from current location.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              )
          );
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Autofill failed. Check internet/Play Services. $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            )
        );
      }
    }
  }

  // --- SAVE TO SUPABASE ---
  Future<void> _saveAddress() async {
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Construct a clean, single string address
        final addressParts = [
          if (_buildingCtrl.text.isNotEmpty) _buildingCtrl.text,
          if (_floorCtrl.text.isNotEmpty) 'Unit ${_floorCtrl.text}',
          if (_streetCtrl.text.isNotEmpty) _streetCtrl.text,
          if (_postalCtrl.text.isNotEmpty || _stateCtrl.text.isNotEmpty)
            '${_postalCtrl.text} ${_stateCtrl.text}'.trim(),
        ];

        final fullAddress = addressParts.join(', ');

        await supabase
            .from('user')
            .update({'address': fullAddress})
            .eq('userid', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('User is not logged in.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            // Map View reverted back to OpenStreetMap
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
                        // Fix: Added "a." subdomain to bypass Flutter's corrupted image cache!
                        urlTemplate: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        // Avoid using the word "example" in this string
                        userAgentPackageName: 'com.student.fooddeliveryapp',
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
                        if (_trackingEnabled) {
                          stopTracking();
                        } else {
                          // Allow autofill to trigger again if they manually press the locate button
                          _hasAutofilled = false;
                          await startTracking();
                        }
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
                        Expanded(child: _buildTextField(context, 'Building name', 'ABC Enterprise', controller: _buildingCtrl)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(context, 'Floor/Unit', '123', controller: _floorCtrl)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(context, 'Street', 'Jalan ABC, Taman Setapak', controller: _streetCtrl),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(context, 'Postal Code', '53000', controller: _postalCtrl)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(context, 'State', 'Kuala Lumpur', controller: _stateCtrl)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(context, 'Delivery Instruction', 'E.g. Leave at lobby...', isOptional: true, maxLines: 3, controller: _instructionCtrl),

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

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text('Save Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
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

  Widget _buildTextField(BuildContext context, String label, String hint, {bool isOptional = false, int maxLines = 1, TextEditingController? controller}) {
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
          controller: controller,
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