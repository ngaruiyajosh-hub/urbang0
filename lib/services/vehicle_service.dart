import 'package:urban_go/models/vehicle_model.dart';

class VehicleService {
  // Simulated vehicle database
  static final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      registrationNumber: 'KA-01-AB-1234',
      type: VehicleType.bus,
      driverId: 'driver1',
      conductorId: 'conductor1',
      totalSeats: 50,
      availableSeats: 45,
      pricePerKm: 2.5,
      status: VehicleStatus.available,
      currentRoute: 'Route 1: Downtown to Airport',
      currentLat: -1.28333,
      currentLng: 36.81667,
      bookedBy: [],
    ),
    Vehicle(
      id: '2',
      registrationNumber: 'KA-02-CD-5678',
      type: VehicleType.van,
      driverId: 'driver2',
      conductorId: 'conductor2',
      totalSeats: 15,
      availableSeats: 10,
      pricePerKm: 3.0,
      status: VehicleStatus.available,
      currentRoute: 'Route 2: Station to Central Hub',
      currentLat: -1.29207,
      currentLng: 36.82195,
      bookedBy: [],
    ),
    Vehicle(
      id: '3',
      registrationNumber: 'KA-03-EF-9012',
      type: VehicleType.car,
      driverId: 'driver3',
      conductorId: 'conductor3',
      totalSeats: 5,
      availableSeats: 2,
      pricePerKm: 4.0,
      status: VehicleStatus.onTrip,
      currentRoute: 'Route 3: Mall to Residential Area',
      currentLat: -1.286389,
      currentLng: 36.817223,
      bookedBy: ['passenger1', 'passenger2', 'passenger3'],
    ),
  ];

  // Get all vehicles
  static Future<List<Vehicle>> getAllVehicles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _vehicles;
  }

  // Get available vehicles
  static Future<List<Vehicle>> getAvailableVehicles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _vehicles.where((v) => v.status == VehicleStatus.available && v.availableSeats > 0).toList();
  }

  // Get vehicles by route
  static Future<List<Vehicle>> getVehiclesByRoute(String route) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _vehicles.where((v) => v.currentRoute == route).toList();
  }

  // Get vehicle by ID
  static Future<Vehicle?> getVehicleById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Book seats in a vehicle
  static Future<bool> bookSeats({
    required String vehicleId,
    required int seatsToBook,
    required String passengerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (vehicleIndex == -1) return false;

    final vehicle = _vehicles[vehicleIndex];
    if (vehicle.availableSeats >= seatsToBook) {
      final updatedVehicle = vehicle.copyWith(
        availableSeats: vehicle.availableSeats - seatsToBook,
        bookedBy: [...vehicle.bookedBy, passengerId],
      );
      _vehicles[vehicleIndex] = updatedVehicle;
      return true;
    }
    return false;
  }

  // Cancel booking (release seats)
  static Future<bool> cancelBooking({
    required String vehicleId,
    required int seatsToRelease,
    required String passengerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (vehicleIndex == -1) return false;

    final vehicle = _vehicles[vehicleIndex];
    final updatedVehicle = vehicle.copyWith(
      availableSeats: vehicle.availableSeats + seatsToRelease,
      bookedBy: vehicle.bookedBy.where((id) => id != passengerId).toList(),
    );
    _vehicles[vehicleIndex] = updatedVehicle;
    return true;
  }

  // Update vehicle status
  static Future<bool> updateVehicleStatus({
    required String vehicleId,
    required VehicleStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (vehicleIndex == -1) return false;

    final vehicle = _vehicles[vehicleIndex];
    _vehicles[vehicleIndex] = vehicle.copyWith(status: status);
    return true;
  }

  // Update vehicle position
  static Future<bool> updateVehiclePosition({
    required String vehicleId,
    required double lat,
    required double lng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (vehicleIndex == -1) return false;
    final vehicle = _vehicles[vehicleIndex];
    _vehicles[vehicleIndex] = vehicle.copyWith(currentLat: lat, currentLng: lng);
    return true;
  }
}
