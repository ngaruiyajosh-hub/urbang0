import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../services/supabase_service.dart';
import '../../services/location_simulator_service.dart';

/// Driver Tracking Screen - Shows simulated driver location and ETA
class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final LocationSimulatorService _locationService = LocationSimulatorService();
  StreamSubscription<DriverLocation>? _locationSubscription;
  Timer? _statusTimer;
  final _supabase = SupabaseService.client;

  DriverLocation? _currentLocation;
  Map<String, dynamic>? _bookingData;
  String _tripStatus = 'driver_assigned';
  bool _isSimulatingMovement = false;

  // Destination (passenger pickup location in Nairobi)
  final double _pickupLat = -1.2921;
  final double _pickupLng = 36.8219;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bookingData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final bookingId = _bookingData?['id']?.toString();
      if (bookingId != null && bookingId.isNotEmpty) {
        _startStatusPolling(bookingId);
      }
      _startTracking();
    });
  }

  void _startTracking() {
    // Start location simulation
    _updateMovementForStatus(_tripStatus);
  }

  void _startMovement() {
    if (_isSimulatingMovement) return;
    _isSimulatingMovement = true;

    _locationService.startSimulation(
      destinationLat: _pickupLat,
      destinationLng: _pickupLng,
    );

    _locationSubscription?.cancel();
    _locationSubscription = _locationService.locationStream.listen((location) {
      setState(() {
        _currentLocation = location;
      });
    });
  }

  void _stopMovement() {
    _isSimulatingMovement = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopSimulation();
  }

  void _updateMovementForStatus(String status) {
    if (status == 'driver_arriving' || status == 'in_progress') {
      _startMovement();
    } else if (status == 'completed') {
      _stopMovement();
    }
  }

  void _startStatusPolling(String bookingId) {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final booking = await _supabase
            .from('Bookings')
            .select('trip_status')
            .eq('id', bookingId)
            .maybeSingle();
        if (booking == null) return;
        final status = (booking['trip_status'] ?? 'driver_assigned').toString();
        if (status != _tripStatus && mounted) {
          setState(() {
            _tripStatus = status;
          });
          _updateMovementForStatus(status);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleData = _bookingData?['Vehicle'] ?? {};
    final statusMessage = _passengerMessageForStatus(_tripStatus);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Track Driver'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map View (Simulated)
          Expanded(flex: 3, child: _buildMapView(theme)),

          // Driver Info & ETA Card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ETA Banner
                if (_currentLocation != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: Colors.white, size: 6.w),
                        SizedBox(width: 2.w),
                        Text(
                          _currentLocation!.estimatedArrivalMinutes == 0
                              ? 'Driver has arrived!'
                              : 'Arriving in ${_currentLocation!.estimatedArrivalMinutes} min',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(3.w),
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 5.w,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          statusMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Driver & Vehicle Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8.w,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 8.w,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicleData['User']?['name'] ?? 'Driver',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 4.w,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${vehicleData['vehicle_type'] ?? 'Vehicle'} • ${vehicleData['license_plate'] ?? 'N/A'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.phone,
                        color: theme.colorScheme.primary,
                        size: 6.w,
                      ),
                      tooltip: 'Call Driver',
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                if (_currentLocation != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.navigation,
                          size: 5.w,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            '${_currentLocation!.distanceKm.toStringAsFixed(1)} km away • Moving toward pickup',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Trip Details
                _buildTripDetail(
                  theme,
                  Icons.location_on,
                  'Pickup',
                  _bookingData?['pickup_location'] ?? 'Pickup location',
                ),
                SizedBox(height: 1.h),
                _buildTripDetail(
                  theme,
                  Icons.flag,
                  'Drop-off',
                  _bookingData?['dropoff_location'] ?? 'Drop-off location',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Map placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 20.w,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Nairobi, Kenya',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Driver location marker (animated)
          if (_currentLocation != null)
            Positioned(
              top: 40.h,
              left: 45.w,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
              ),
            ),

          // Pickup location marker
          Positioned(
            top: 20.h,
            right: 30.w,
            child: Column(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 10.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Pickup',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location coordinates display (for simulation visibility)
          if (_currentLocation != null)
            Positioned(
              top: 2.h,
              left: 4.w,
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Location:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Lng: ${_currentLocation!.longitude.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripDetail(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 5.w, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _passengerMessageForStatus(String status) {
    switch (status) {
      case 'driver_assigned':
        return 'Driver assigned';
      case 'driver_arriving':
        return 'Driver arriving';
      case 'trip_started':
        return 'Trip started';
      case 'in_progress':
        return 'On the way';
      case 'completed':
        return 'Trip completed';
      default:
        return 'Driver assigned';
    }
  }
}
