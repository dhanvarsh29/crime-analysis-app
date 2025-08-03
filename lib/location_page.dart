import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  LatLng? _currentPosition;
  String _pincode = '';
  final String _zone = 'Chennai South';
  final TextEditingController _areaController = TextEditingController();
  String _apiResponse = '';
  Map<String, dynamic>? _predictionData;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = latLng;
      });

      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          _pincode = placemarks.first.postalCode ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _apiResponse = '❌ Location error: $e';
      });
    }
  }

  Future<void> _predictCrimeRisk() async {
    final areaName = _areaController.text.trim().isEmpty
        ? "T. Nagar"
        : _areaController.text.trim();

    if (_currentPosition == null || _pincode.isEmpty) {
      setState(() {
        _apiResponse = '❌ Location or pincode not ready.';
      });
      return;
    }

    final Map<String, dynamic> payload = {
      "Area_Name": areaName,
      "Pincode": _pincode,
      "Latitude": _currentPosition!.latitude,
      "Longitude": _currentPosition!.longitude,
      "Zone_Name": _zone,
    };

    print("📦 Payload: $payload");

    try {
      final response = await http.post(
        Uri.parse('https://crimes-api-1jdn.onrender.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictionData = data;
          _apiResponse = '';
        });
      } else {
        setState(() {
          _predictionData = null;
          _apiResponse = '❌ API Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _predictionData = null;
        _apiResponse = '❌ Network error: $e';
      });
    }
  }

  // Decode functions
  String decodeBoolean(double value) => value >= 0.5 ? 'Yes' : 'No';
  String decodeGender(double value) => value < 0.5 ? 'Male' : 'Female';

  String decodeCrimeType(double value) {
    if (value < 1) return 'Theft';
    if (value < 2) return 'Assault';
    if (value < 3) return 'Robbery';
    if (value < 4) return 'Burglary';
    return 'Other';
  }

  String decodeCrimeSubtype(double value) {
    if (value < 2) return 'Pickpocketing';
    if (value < 4) return 'Mugging';
    if (value < 6) return 'Armed Robbery';
    if (value < 8) return 'Break-In';
    return 'Other';
  }

  String decodeAgeGroup(double value) {
    if (value < 1) return 'Child';
    if (value < 2) return 'Teenager';
    if (value < 3) return 'Adult';
    return 'Senior';
  }

  String getRiskLevelLabel(dynamic riskRaw) {
    double risk = 0.0;

    if (riskRaw is double) {
      risk = riskRaw;
    } else if (riskRaw is int) {
      risk = riskRaw.toDouble();
    } else if (riskRaw is String) {
      risk = double.tryParse(riskRaw) ?? 0.0;
    }

    if (risk < 5) return 'Low';
    if (risk < 15) return 'Medium';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crime Risk Predictor")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentPosition != null)
                  SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _currentPosition!,
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area Name (default: T. Nagar)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                if (_currentPosition != null) ...[
                  Text("📍 Pincode: $_pincode"),
                  Text("🌐 Latitude: ${_currentPosition!.latitude}, Longitude: ${_currentPosition!.longitude}"),
                  Text("🧭 Zone: $_zone"),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _predictCrimeRisk,
                  child: const Text("Predict Crime Risk"),
                ),
                const SizedBox(height: 20),
                if (_predictionData != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Risk Level: ${getRiskLevelLabel(_predictionData!['Risk_Level'])} (${(_predictionData!['Risk_Level'] ?? 0.0).toStringAsFixed(2)})", style: const TextStyle(color: Colors.white)),
                        Text("Arrest Made: ${decodeBoolean(_predictionData!['Arrest_Made'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("CCTV Captured: ${decodeBoolean(_predictionData!['CCTV_Captured'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Crime Severity: ${(_predictionData!['Crime_Severity'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(color: Colors.white)),
                        Text("Crime Type: ${decodeCrimeType(_predictionData!['Crime_Type'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Crime Subtype: ${decodeCrimeSubtype(_predictionData!['Crime_Subtype'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Gang Involvement: ${decodeBoolean(_predictionData!['Gang_Involvement'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Reported By Public: ${decodeBoolean(_predictionData!['Reported_By'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Vehicle Used: ${decodeBoolean(_predictionData!['Vehicle_Used'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Weapon Used: ${decodeBoolean(_predictionData!['Weapon_Used'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Victim Age Group: ${decodeAgeGroup(_predictionData!['Victim_Age_Group'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                        Text("Victim Gender: ${decodeGender(_predictionData!['Victim_Gender'] ?? 0.0)}", style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                else if (_apiResponse.isNotEmpty)
                  Text(_apiResponse, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
