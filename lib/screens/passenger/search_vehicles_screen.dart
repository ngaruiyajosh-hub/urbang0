import 'package:flutter/material.dart';
import 'package:urban_go/services/vehicle_service.dart';
import 'package:urban_go/services/gps_service.dart';
import 'package:urban_go/services/geocoding_service.dart';
import 'package:urban_go/screens/common/vehicle_map.dart';
import 'package:urban_go/services/route_service.dart';
import 'package:urban_go/models/vehicle_model.dart';
import 'package:urban_go/screens/passenger/booking_screen.dart';

class SearchVehiclesScreen extends StatefulWidget {
  const SearchVehiclesScreen({super.key});

  @override
  State<SearchVehiclesScreen> createState() => _SearchVehiclesScreenState();
}

class _SearchVehiclesScreenState extends State<SearchVehiclesScreen> {
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;
  List<Vehicle> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _handleSearch() async {
    setState(() {
      _isSearching = true;
    });

    try {
      // If the user typed an address but we don't have coords yet, geocode it
      if (_pickupController.text.isNotEmpty && (_pickupLat == null || _pickupLng == null)) {
        final result = await GeocodingService.geocodeAddress(_pickupController.text);
        if (result != null) {
          _pickupLat = result['lat'] as double?;
          _pickupLng = result['lng'] as double?;
          // Optionally update the displayed text to the formatted address
          _pickupController.text = result['formattedAddress'] as String? ?? _pickupController.text;
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not geocode pickup address')));
        }
      }

      if (_dropController.text.isNotEmpty && (_dropLat == null || _dropLng == null)) {
        final result = await GeocodingService.geocodeAddress(_dropController.text);
        if (result != null) {
          _dropLat = result['lat'] as double?;
          _dropLng = result['lng'] as double?;
          _dropController.text = result['formattedAddress'] as String? ?? _dropController.text;
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not geocode drop address')));
        }
      }

      final vehicles = await VehicleService.getAvailableVehicles();
      setState(() {
        _searchResults = vehicles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Vehicles'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search filters
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _pickupController,
                        decoration: InputDecoration(
                          labelText: 'Pickup Location',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: () async {
                              final pos = await GpsService.getCurrentPosition();
                              if (pos != null) {
                                setState(() {
                                  _pickupController.text = 'Current location';
                                  _pickupLat = pos.latitude;
                                  _pickupLng = pos.longitude;
                                });
                              } else {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not available')));
                              }
                            },
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dropController,
                        decoration: InputDecoration(
                          labelText: 'Drop Location',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.place),
                            onPressed: () async {
                              final pos = await GpsService.getCurrentPosition();
                              if (pos != null) {
                                setState(() {
                                  _dropController.text = 'Current location';
                                  _dropLat = pos.latitude;
                                  _dropLng = pos.longitude;
                                });
                              } else {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not available')));
                              }
                            },
                          ),
                          prefixIcon: const Icon(Icons.location_off),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _handleSearch,
                          child: _isSearching
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Search Vehicles'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Search results
              if (_searchResults.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_searchResults.length} vehicles found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final vehicle = _searchResults[index];
                        return _buildVehicleCard(context, vehicle);
                      },
                    ),
                  ],
                )
              else if (_searchResults.isEmpty && !_isSearching)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Icon(
                        Icons.directions_bus,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No vehicles found. Try searching!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.registrationNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.type.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: vehicle.availableSeats > 0
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${vehicle.availableSeats} seats',
                    style: TextStyle(
                      color: vehicle.availableSeats > 0
                          ? Colors.green[900]
                          : Colors.red[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.currentRoute,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price per km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₹${vehicle.pricePerKm}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => VehicleMap(
                            userLat: _pickupLat,
                            userLng: _pickupLng,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.map),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: vehicle.availableSeats > 0
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BookingScreen(
                                      vehicle: vehicle,
                                      pickupLocation: _pickupController.text,
                                      dropLocation: _dropController.text,
                                      pickupLat: _pickupLat,
                                      pickupLng: _pickupLng,
                                      dropLat: _dropLat,
                                      dropLng: _dropLng,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: const Text('Book Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
