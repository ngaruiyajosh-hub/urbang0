// Route model
class Route {
  final String id;
  final String name;
  final String startPoint;
  final String endPoint;
  final List<String> stops; // Intermediate stops
  final double distance; // in kilometers
  final int estimatedTime; // in minutes
  final bool isActive;

  Route({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    required this.distance,
    required this.estimatedTime,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'stops': stops,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'isActive': isActive,
    };
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'],
      name: json['name'],
      startPoint: json['startPoint'],
      endPoint: json['endPoint'],
      stops: List<String>.from(json['stops'] ?? []),
      distance: (json['distance'] as num).toDouble(),
      estimatedTime: json['estimatedTime'],
      isActive: json['isActive'] ?? true,
    );
  }
}
