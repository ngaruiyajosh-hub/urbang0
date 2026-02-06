// Vehicle type enum
enum VehicleType {
  bus,
  van,
  car,
}

// Vehicle status enum
enum VehicleStatus {
  available,
  onTrip,
  maintenance,
}

// Vehicle model
class Vehicle {
  final String id;
  final String registrationNumber;
  final VehicleType type;
  final String driverId;
  final String conductorId;
  final int totalSeats;
  final int availableSeats;
  final double pricePerKm;
  final VehicleStatus status;
  final String currentRoute;
  final double? currentLat;
  final double? currentLng;
  final List<String> bookedBy; // List of passenger IDs

  Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.type,
    required this.driverId,
    required this.conductorId,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerKm,
    required this.status,
    required this.currentRoute,
    this.currentLat,
    this.currentLng,
    this.bookedBy = const [],
  });

  // Copy with modifications
  Vehicle copyWith({
    int? availableSeats,
    VehicleStatus? status,
    String? currentRoute,
    List<String>? bookedBy,
    double? currentLat,
    double? currentLng,
  }) {
    return Vehicle(
      id: id,
      registrationNumber: registrationNumber,
      type: type,
      driverId: driverId,
      conductorId: conductorId,
      totalSeats: totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      pricePerKm: pricePerKm,
      status: status ?? this.status,
      currentRoute: currentRoute ?? this.currentRoute,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      bookedBy: bookedBy ?? this.bookedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationNumber': registrationNumber,
      'type': type.toString(),
      'driverId': driverId,
      'conductorId': conductorId,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'pricePerKm': pricePerKm,
      'status': status.toString(),
      'currentRoute': currentRoute,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'bookedBy': bookedBy,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      registrationNumber: json['registrationNumber'],
      type: VehicleType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      driverId: json['driverId'],
      conductorId: json['conductorId'],
      totalSeats: json['totalSeats'],
      availableSeats: json['availableSeats'],
      pricePerKm: (json['pricePerKm'] as num).toDouble(),
      status: VehicleStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      currentRoute: json['currentRoute'],
      currentLat: json['currentLat'] != null ? (json['currentLat'] as num).toDouble() : null,
      currentLng: json['currentLng'] != null ? (json['currentLng'] as num).toDouble() : null,
      bookedBy: List<String>.from(json['bookedBy'] ?? []),
    );
  }
}
