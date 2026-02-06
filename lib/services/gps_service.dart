import 'dart:async';

import 'package:geolocator/geolocator.dart';

class GpsService {
  // Request permission and get current position
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Stream position updates
  static Stream<Position> getPositionStream({LocationSettings? settings}) {
    final locationSettings = settings ?? const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
