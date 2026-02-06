import 'package:urban_go/models/route_model.dart';

class RouteService {
  // Simulated route database
  static final List<Route> _routes = [
    Route(
      id: '1',
      name: 'Downtown Express',
      startPoint: 'Central Station',
      endPoint: 'Airport Terminal',
      stops: ['Bus Stop A', 'Shopping Mall', 'City Center', 'Highway Plaza'],
      distance: 25.5,
      estimatedTime: 45,
      isActive: true,
    ),
    Route(
      id: '2',
      name: 'Residential Route',
      startPoint: 'Main Bus Station',
      endPoint: 'Residential Complex',
      stops: ['Market Square', 'Hospital', 'School', 'Park'],
      distance: 15.3,
      estimatedTime: 30,
      isActive: true,
    ),
    Route(
      id: '3',
      name: 'University Shuttle',
      startPoint: 'City Center',
      endPoint: 'University Campus',
      stops: ['Tech Park', 'Sports Complex', 'Student Hostel'],
      distance: 12.0,
      estimatedTime: 25,
      isActive: true,
    ),
    Route(
      id: '4',
      name: 'Night Route',
      startPoint: 'Station',
      endPoint: 'Entertainment District',
      stops: ['Cinema', 'Restaurant Area', 'Nightclub Zone'],
      distance: 8.5,
      estimatedTime: 20,
      isActive: true,
    ),
  ];

  // Get all routes
  static Future<List<Route>> getAllRoutes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _routes;
  }

  // Get active routes
  static Future<List<Route>> getActiveRoutes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _routes.where((r) => r.isActive).toList();
  }

  // Get route by ID
  static Future<Route?> getRouteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _routes.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search routes by start and end point
  static Future<List<Route>> searchRoutes({
    required String startPoint,
    required String endPoint,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _routes.where((r) => 
      r.startPoint.toLowerCase().contains(startPoint.toLowerCase()) &&
      r.endPoint.toLowerCase().contains(endPoint.toLowerCase())
    ).toList();
  }

  // Get routes containing a specific stop
  static Future<List<Route>> getRoutesByStop(String stopName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _routes.where((r) => 
      r.stops.any((stop) => stop.toLowerCase().contains(stopName.toLowerCase()))
    ).toList();
  }
}
