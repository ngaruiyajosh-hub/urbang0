import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  // Provide your Google Geocoding API key here (or load from secure storage)
  static String apiKey = '';

  /// Geocode an address string using Google Geocoding API.
  /// Returns a map with keys: 'formattedAddress', 'lat', 'lng' on success, or null.
  static Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    if (apiKey.isEmpty) return null;
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$apiKey');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((json['status'] as String?) != 'OK') return null;
    final results = json['results'] as List<dynamic>;
    if (results.isEmpty) return null;
    final first = results[0] as Map<String, dynamic>;
    final location = (first['geometry'] as Map<String, dynamic>)['location'] as Map<String, dynamic>;
    return {
      'formattedAddress': first['formatted_address'],
      'lat': (location['lat'] as num).toDouble(),
      'lng': (location['lng'] as num).toDouble(),
    };
  }

  /// Reverse geocode coordinates to an address (returns formatted address) - optional
  static Future<String?> reverseGeocode(double lat, double lng) async {
    if (apiKey.isEmpty) return null;
    final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=\$lat,\$lng&key=\$apiKey');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((json['status'] as String?) != 'OK') return null;
    final results = json['results'] as List<dynamic>;
    if (results.isEmpty) return null;
    return (results[0] as Map<String, dynamic>)['formatted_address'] as String;
  }
}
