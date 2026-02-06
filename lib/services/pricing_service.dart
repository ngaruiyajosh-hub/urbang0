import 'dart:math';

class PricingService {
  // Haversine distance in kilometers
  static double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;

  // Simple fare calculation: distance * pricePerKm * seats
  static double calculateFare(double distanceKm, double pricePerKm, int seats) {
    final base = distanceKm * pricePerKm;
    // small rounding and minimum fare
    final fare = max(base * seats, 10.0);
    return double.parse(fare.toStringAsFixed(2));
  }

  // Estimate ETA minutes given distance and average speed (km/h)
  static int estimateEtaMinutes(double distanceKm, {double avgSpeedKmph = 30}) {
    if (avgSpeedKmph <= 0) return 0;
    final hours = distanceKm / avgSpeedKmph;
    return (hours * 60).ceil();
  }
}
