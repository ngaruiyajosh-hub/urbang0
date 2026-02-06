// Booking status enum
enum BookingStatus {
  pending,
  confirmed,
  ongoing,
  completed,
  cancelled,
}

// Booking model
class Booking {
  final String id;
  final String passengerId;
  final String vehicleId;
  final String pickupLocation;
  final String dropLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final DateTime bookingTime;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final double fare;
  final int seatsBooked;
  final BookingStatus status;
  final String paymentMethod; // 'digital' or 'cash'
  final bool isPaid;

  Booking({
    required this.id,
    required this.passengerId,
    required this.vehicleId,
    required this.pickupLocation,
    required this.dropLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    required this.bookingTime,
    this.departureTime,
    this.arrivalTime,
    required this.fare,
    required this.seatsBooked,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'vehicleId': vehicleId,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'bookingTime': bookingTime.toIso8601String(),
      'departureTime': departureTime?.toIso8601String(),
      'arrivalTime': arrivalTime?.toIso8601String(),
      'fare': fare,
      'seatsBooked': seatsBooked,
      'status': status.toString(),
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      passengerId: json['passengerId'],
      vehicleId: json['vehicleId'],
      pickupLocation: json['pickupLocation'],
      dropLocation: json['dropLocation'],
        pickupLat: json['pickupLat'] != null ? (json['pickupLat'] as num).toDouble() : null,
        pickupLng: json['pickupLng'] != null ? (json['pickupLng'] as num).toDouble() : null,
        dropLat: json['dropLat'] != null ? (json['dropLat'] as num).toDouble() : null,
        dropLng: json['dropLng'] != null ? (json['dropLng'] as num).toDouble() : null,
      bookingTime: DateTime.parse(json['bookingTime']),
      departureTime: json['departureTime'] != null 
          ? DateTime.parse(json['departureTime'])
          : null,
      arrivalTime: json['arrivalTime'] != null 
          ? DateTime.parse(json['arrivalTime'])
          : null,
      fare: (json['fare'] as num).toDouble(),
      seatsBooked: json['seatsBooked'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'] ?? false,
    );
  }
}
