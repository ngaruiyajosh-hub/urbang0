import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:urban_go/services/vehicle_service.dart';
import 'package:urban_go/models/vehicle_model.dart';
import 'package:urban_go/services/pricing_service.dart';

class VehicleMap extends StatefulWidget {
  final double? userLat;
  final double? userLng;

  const VehicleMap({super.key, this.userLat, this.userLng});

  @override
  State<VehicleMap> createState() => _VehicleMapState();
}

class _VehicleMapState extends State<VehicleMap> {
  final Set<Marker> _markers = {};
  GoogleMapController? _controller;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadVehicles());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await VehicleService.getAllVehicles();
    final newMarkers = <Marker>{};
    for (final v in vehicles) {
      if (v.currentLat == null || v.currentLng == null) continue;
      final position = LatLng(v.currentLat!, v.currentLng!);
      String subtitle = v.currentRoute;
      if (widget.userLat != null && widget.userLng != null) {
        final distance = PricingService.distanceBetween(widget.userLat!, widget.userLng!, v.currentLat!, v.currentLng!);
        final eta = PricingService.estimateEtaMinutes(distance);
        subtitle = '${v.currentRoute} • ${distance.toStringAsFixed(2)} km • ETA ${eta} min';
      }

      newMarkers.add(Marker(
        markerId: MarkerId(v.id),
        position: position,
        infoWindow: InfoWindow(title: v.registrationNumber, snippet: subtitle),
      ));
    }
    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Vehicles')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.userLat != null && widget.userLng != null
              ? LatLng(widget.userLat!, widget.userLng!)
              : const LatLng(-1.286389, 36.817223),
          zoom: 13,
        ),
        markers: _markers,
        onMapCreated: (c) => _controller = c,
      ),
    );
  }
}
