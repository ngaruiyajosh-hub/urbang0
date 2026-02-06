import 'dart:async';

import 'package:flutter/material.dart';
import 'package:urban_go/services/auth_service.dart';
import 'package:urban_go/services/driver_position_service.dart';
import 'package:urban_go/services/gps_service.dart';
import 'package:urban_go/services/vehicle_service.dart';
import 'package:urban_go/models/vehicle_model.dart';

class DriverPositionUploader extends StatefulWidget {
  const DriverPositionUploader({super.key});

  @override
  State<DriverPositionUploader> createState() => _DriverPositionUploaderState();
}

class _DriverPositionUploaderState extends State<DriverPositionUploader> {
  bool _streaming = false;
  String? _selectedVehicleId;
  double? _currentLat;
  double? _currentLng;
  List<Vehicle> _myVehicles = [];
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final user = AuthService.getCurrentUser();
    if (user == null) return;
    final vehicles = await VehicleService.getAllVehicles();
    setState(() {
      _myVehicles = vehicles.where((v) => v.driverId == user.id).toList();
      if (_myVehicles.isNotEmpty && _selectedVehicleId == null) {
        _selectedVehicleId = _myVehicles.first.id;
      }
    });
  }

  Future<void> _uploadNow() async {
    final user = AuthService.getCurrentUser();
    if (user == null || _selectedVehicleId == null) return;
    final pos = await GpsService.getCurrentPosition();
    if (pos == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS not available')));
      return;
    }
    final ok = await DriverPositionService.uploadPosition(
      vehicleId: _selectedVehicleId!,
      driverId: user.id,
      lat: pos.latitude,
      lng: pos.longitude,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Position uploaded' : 'Upload failed')));
    setState(() {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
    });
  }

  Future<void> _toggleStreaming() async {
    final user = AuthService.getCurrentUser();
    if (user == null || _selectedVehicleId == null) return;

    if (!_streaming) {
      final started = await DriverPositionService.startStreaming(
        vehicleId: _selectedVehicleId!,
        driverId: user.id,
      );
      if (started) {
        // update current position locally via one-time get
        final pos = await GpsService.getCurrentPosition();
        setState(() {
          _streaming = true;
          _currentLat = pos?.latitude;
          _currentLng = pos?.longitude;
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start streaming')));
      }
    } else {
      await DriverPositionService.stopStreaming();
      setState(() {
        _streaming = false;
      });
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    DriverPositionService.stopStreaming();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Position Uploader')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) Text('Logged in as: ${user.name} (${user.id})'),
            const SizedBox(height: 12),
            const Text('Select Vehicle:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedVehicleId,
              items: _myVehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.registrationNumber))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedVehicleId = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Current Position: ${_currentLat?.toStringAsFixed(6) ?? '-'}, ${_currentLng?.toStringAsFixed(6) ?? '-'}'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _uploadNow,
                  child: const Text('Upload Now'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _toggleStreaming,
                  style: ElevatedButton.styleFrom(backgroundColor: _streaming ? Colors.red : null),
                  child: Text(_streaming ? 'Stop Streaming' : 'Start Streaming'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Notes:'),
            const SizedBox(height: 8),
            const Text('- This will write to the Supabase table `driver_positions`.')
          ],
        ),
      ),
    );
  }
}
