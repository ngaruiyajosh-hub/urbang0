import 'dart:async';
import 'dart:math';

/// Simple location simulator for driver tracking in Nairobi, Kenya
class LocationSimulatorService {
  // Nairobi city center coordinates
  static const double nairobiCenterLat = -1.2864;
  static const double nairobiCenterLng = 36.8172;

  // Simulation parameters
  static const int updateIntervalSeconds = 2;
  static const double speedMetersPerSecond = 8.0; // ~28.8 km/h
  static const double maxJitterMeters = 6.0; // random drift per update

  Timer? _simulationTimer;
  final _locationController = StreamController<DriverLocation>.broadcast();

  double _currentLat = nairobiCenterLat;
  double _currentLng = nairobiCenterLng;
  double _destinationLat = 0.0;
  double _destinationLng = 0.0;
  int _estimatedTimeMinutes = 0;
  double _distanceKm = 0.0;
  final Random _random = Random();

  Stream<DriverLocation> get locationStream => _locationController.stream;

  /// Start simulating driver movement from random Nairobi location to destination
  void startSimulation({
    required double destinationLat,
    required double destinationLng,
  }) {
    // Start from random location in Nairobi area (within ~5km radius)
    _currentLat = nairobiCenterLat + (_random.nextDouble() - 0.5) * 0.09;
    _currentLng = nairobiCenterLng + (_random.nextDouble() - 0.5) * 0.09;
    _destinationLat = destinationLat;
    _destinationLng = destinationLng;

    // Calculate initial ETA
    _estimatedTimeMinutes = _calculateETA();
    _distanceKm = _calculateDistanceKm();

    // Emit initial location
    _emitLocation();

    // Start periodic updates
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(
      const Duration(seconds: updateIntervalSeconds),
      (_) => _updateLocation(),
    );
  }

  void _updateLocation() {
    final distanceMeters = _calculateDistanceMeters();

    // Check if arrived
    final stepMeters = speedMetersPerSecond * updateIntervalSeconds;
    if (distanceMeters <= stepMeters) {
      _currentLat = _destinationLat;
      _currentLng = _destinationLng;
      _estimatedTimeMinutes = 0;
      _distanceKm = 0.0;
      _emitLocation();
      stopSimulation();
      return;
    }

    // Move towards destination
    _moveTowardsDestination(stepMeters);
    _applyJitter();

    // Update ETA
    _estimatedTimeMinutes = _calculateETA();
    _distanceKm = _calculateDistanceKm();

    _emitLocation();
  }

  int _calculateETA() {
    final distanceMeters = _calculateDistanceMeters();
    final secondsNeeded = distanceMeters / speedMetersPerSecond;
    return max(1, (secondsNeeded / 60).ceil());
  }

  double _calculateDistanceKm() {
    return _calculateDistanceMeters() / 1000;
  }

  double _calculateDistanceMeters() {
    const double earthRadiusMeters = 6371000;
    final lat1 = _degToRad(_currentLat);
    final lat2 = _degToRad(_destinationLat);
    final deltaLat = _degToRad(_destinationLat - _currentLat);
    final deltaLng = _degToRad(_destinationLng - _currentLng);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  void _moveTowardsDestination(double stepMeters) {
    final bearing = _bearingRadians(
      _currentLat,
      _currentLng,
      _destinationLat,
      _destinationLng,
    );
    _moveByMeters(stepMeters, bearing);
  }

  void _applyJitter() {
    final jitterMeters = _random.nextDouble() * maxJitterMeters;
    final jitterBearing = _random.nextDouble() * 2 * pi;
    _moveByMeters(jitterMeters, jitterBearing);
  }

  void _moveByMeters(double meters, double bearingRadians) {
    const double metersPerDegreeLat = 111320;
    final metersPerDegreeLng = metersPerDegreeLat * cos(_degToRad(_currentLat));

    final deltaLat = (meters * cos(bearingRadians)) / metersPerDegreeLat;
    final deltaLng = (meters * sin(bearingRadians)) / metersPerDegreeLng;

    _currentLat += deltaLat;
    _currentLng += deltaLng;
  }

  double _bearingRadians(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final lat1Rad = _degToRad(lat1);
    final lat2Rad = _degToRad(lat2);
    final deltaLng = _degToRad(lng2 - lng1);
    final y = sin(deltaLng) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(deltaLng);
    return atan2(y, x);
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void _emitLocation() {
    _locationController.add(
      DriverLocation(
        latitude: _currentLat,
        longitude: _currentLng,
        estimatedArrivalMinutes: _estimatedTimeMinutes,
        distanceKm: _distanceKm,
      ),
    );
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void dispose() {
    stopSimulation();
    _locationController.close();
  }
}

class DriverLocation {
  final double latitude;
  final double longitude;
  final int estimatedArrivalMinutes;
  final double distanceKm;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.estimatedArrivalMinutes,
    required this.distanceKm,
  });
}
