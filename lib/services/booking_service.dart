import 'package:urban_go/models/booking_model.dart';
import 'package:urban_go/services/vehicle_service.dart';
import 'package:urban_go/services/pricing_service.dart';

class BookingService {
  // Simulated booking database
  static final List<Booking> _bookings = [];

  // Create a new booking
  static Future<String?> createBooking({
    required String passengerId,
    required String vehicleId,
    required String pickupLocation,
    required String dropLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    required int seatsBooked,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Determine fare automatically using vehicle pricePerKm and distance
    final vehicle = await VehicleService.getVehicleById(vehicleId);
    double fare = 0.0;
    if (vehicle != null && pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
      final distanceKm = PricingService.distanceBetween(
        pickupLat,
        pickupLng,
        dropLat,
        dropLng,
      );
      fare = PricingService.calculateFare(distanceKm, vehicle.pricePerKm, seatsBooked);
    }

    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      passengerId: passengerId,
      vehicleId: vehicleId,
      pickupLocation: pickupLocation,
      dropLocation: dropLocation,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
      bookingTime: DateTime.now(),
      fare: fare,
      seatsBooked: seatsBooked,
      status: BookingStatus.pending,
      paymentMethod: paymentMethod,
      isPaid: paymentMethod == 'digital', // Auto-pay for digital (assumes payment handled separately)
    );

    _bookings.add(booking);
    return booking.id;
  }

  // Get bookings by passenger
  static Future<List<Booking>> getBookingsByPassenger(String passengerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings.where((b) => b.passengerId == passengerId).toList();
  }

  // Get bookings by vehicle
  static Future<List<Booking>> getBookingsByVehicle(String vehicleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings.where((b) => b.vehicleId == vehicleId).toList();
  }

  // Get booking by ID
  static Future<Booking?> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update booking status
  static Future<bool> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
    if (bookingIndex == -1) return false;

    final booking = _bookings[bookingIndex];
    _bookings[bookingIndex] = Booking(
      id: booking.id,
      passengerId: booking.passengerId,
      vehicleId: booking.vehicleId,
      pickupLocation: booking.pickupLocation,
      dropLocation: booking.dropLocation,
      bookingTime: booking.bookingTime,
      departureTime: status == BookingStatus.ongoing ? DateTime.now() : booking.departureTime,
      arrivalTime: status == BookingStatus.completed ? DateTime.now() : booking.arrivalTime,
      fare: booking.fare,
      seatsBooked: booking.seatsBooked,
      status: status,
      paymentMethod: booking.paymentMethod,
      isPaid: booking.isPaid,
    );
    return true;
  }

  // Cancel booking
  static Future<bool> cancelBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
    if (bookingIndex == -1) return false;

    final booking = _bookings[bookingIndex];
    _bookings[bookingIndex] = Booking(
      id: booking.id,
      passengerId: booking.passengerId,
      vehicleId: booking.vehicleId,
      pickupLocation: booking.pickupLocation,
      dropLocation: booking.dropLocation,
      bookingTime: booking.bookingTime,
      departureTime: booking.departureTime,
      arrivalTime: booking.arrivalTime,
      fare: booking.fare,
      seatsBooked: booking.seatsBooked,
      status: BookingStatus.cancelled,
      paymentMethod: booking.paymentMethod,
      isPaid: false,
    );
    return true;
  }

  // Process payment
  static Future<bool> processPayment({
    required String bookingId,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
    if (bookingIndex == -1) return false;

    final booking = _bookings[bookingIndex];
    _bookings[bookingIndex] = Booking(
      id: booking.id,
      passengerId: booking.passengerId,
      vehicleId: booking.vehicleId,
      pickupLocation: booking.pickupLocation,
      dropLocation: booking.dropLocation,
      bookingTime: booking.bookingTime,
      departureTime: booking.departureTime,
      arrivalTime: booking.arrivalTime,
      fare: booking.fare,
      seatsBooked: booking.seatsBooked,
      status: BookingStatus.confirmed,
      paymentMethod: paymentMethod,
      isPaid: true,
    );
    return true;
  }
}
