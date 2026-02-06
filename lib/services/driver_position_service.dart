import 'dart:async';

import 'package:urban_go/services/supabase_service.dart';
import 'package:urban_go/services/gps_service.dart';

class DriverPositionService {
  static StreamSubscription? _streamSub;

  /// Upload a single position to Supabase table `driver_positions`.
  /// Table expected columns: vehicle_id, driver_id, lat, lng, created_at
  static Future<bool> uploadPosition({
    required String vehicleId,
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      await SupabaseService.client
          .from('driver_positions')
          .insert({
        'vehicle_id': vehicleId,
        'driver_id': driverId,
        'lat': lat,
        'lng': lng,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start streaming device GPS to Supabase every time the device reports a new position.
  /// Returns true if streaming started.
  static Future<bool> startStreaming({
    required String vehicleId,
    required String driverId,
  }) async {
    // ensure any previous stream is cancelled
    await stopStreaming();

    try {
      _streamSub = GpsService.getPositionStream().listen((pos) async {
        await uploadPosition(
          vehicleId: vehicleId,
          driverId: driverId,
          lat: pos.latitude,
          lng: pos.longitude,
        );
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop streaming GPS updates.
  static Future<void> stopStreaming() async {
    await _streamSub?.cancel();
    _streamSub = null;
  }
}
