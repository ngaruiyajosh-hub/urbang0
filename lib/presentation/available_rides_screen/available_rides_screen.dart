import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'dart:math';

import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../services/mpesa_service.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/vehicle_card_widget.dart';

/// Available Rides Screen - Shows vehicles with live location and booking options
class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Economy', 'Premium', 'Shared'];
  final Random _random = Random();
  Timer? _mapTimer;
  final List<Offset> _carPositions = [];

  static const double _baseFare = 100;
  static const double _perKmRate = 50;
  static const double _perMinuteRate = 5;
  static const double _minimumFare = 50;
  static const double _avgCitySpeedKph = 25;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _initMapSimulation();
  }

  @override
  void dispose() {
    _mapTimer?.cancel();
    super.dispose();
  }

  void _initMapSimulation() {
    _carPositions.clear();
    for (int i = 0; i < 6; i++) {
      _carPositions.add(
        Offset(_random.nextDouble(), _random.nextDouble()),
      );
    }
    _mapTimer?.cancel();
    _mapTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      setState(() {
        for (int i = 0; i < _carPositions.length; i++) {
          final current = _carPositions[i];
          final dx = (_random.nextDouble() - 0.5) * 0.08;
          final dy = (_random.nextDouble() - 0.5) * 0.08;
          final next = Offset(
            (current.dx + dx).clamp(0.05, 0.95),
            (current.dy + dy).clamp(0.05, 0.95),
          );
          _carPositions[i] = next;
        }
      });
    });
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() => _isLoading = true);
      final response = await _supabase
          .from('Vehicle')
          .select('*, User!Vehicle_driver_id_fkey(name)')
          .eq('status', 'Available')
          .gt('available_seats', 0);

      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredVehicles {
    if (_selectedFilter == 'All') return _vehicles;
    return _vehicles
        .where((v) => v['vehicle_type'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Map View Placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 20.w,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Map View',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Vehicle locations will appear here',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._carPositions.map(
                      (pos) => Positioned(
                        left: pos.dx * width,
                        top: pos.dy * height,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          padding: EdgeInsets.all(1.2.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 5.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shield_outlined),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Emergency contacts available'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with Rides
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 1.h),
                      width: 12.w,
                      height: 0.5.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        children: [
                          Text(
                            'Available Rides',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadVehicles,
                          ),
                        ],
                      ),
                    ),

                    // Filter Chips
                    SizedBox(
                      height: 6.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          return FilterChipWidget(
                            label: _filters[index],
                            isSelected: _selectedFilter == _filters[index],
                            onTap: () {
                              setState(() => _selectedFilter = _filters[index]);
                            },
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 1.h),

                    // Vehicle List
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : _filteredVehicles.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 15.w,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'No vehicles available',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              itemCount: _filteredVehicles.length,
                              itemBuilder: (context, index) {
                                return VehicleCardWidget(
                                  vehicle: _filteredVehicles[index],
                                  onBook: () =>
                                      _bookRide(_filteredVehicles[index]),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _bookRide(Map<String, dynamic> vehicle) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a ride')),
      );
      return;
    }

    // Check available seats
    final availableSeats = vehicle['available_seats'] ?? 0;
    if (availableSeats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No seats available for this vehicle')),
      );
      return;
    }

    // Show booking dialog with M-Pesa payment
    // Convert User object to Map for compatibility
    final userMap = {
      'id': currentUser.id,
      'name': currentUser.userMetadata?['name'] ?? '',
      'email': currentUser.email ?? '',
    };
    _showBookingDialog(vehicle, userMap);
  }

  void _showBookingDialog(
    Map<String, dynamic> vehicle,
    Map<String, dynamic> user,
  ) {
    final phoneController = TextEditingController();
    final pickupController = TextEditingController();
    final dropoffController = TextEditingController();
    double? simulatedDistanceKm;
    int? simulatedDurationMin;
    double? simulatedFare;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updateSimulation() {
            final pickup = pickupController.text.trim();
            final dropoff = dropoffController.text.trim();
            if (pickup.isEmpty || dropoff.isEmpty) {
              return;
            }

            simulatedDistanceKm = _randomDistanceKm();
            simulatedDurationMin =
                _estimateDurationMinutes(simulatedDistanceKm!);
            simulatedFare = _calculateFare(
              simulatedDistanceKm!,
              simulatedDurationMin!,
            );
          }

          return AlertDialog(
            title: Text('Book ${vehicle['vehicle_type']} Ride'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver: ${vehicle['User']['name']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 1.h),
                  Text('Available Seats: ${vehicle['available_seats']}'),
                  if (simulatedFare != null) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      'Distance: ${simulatedDistanceKm!.toStringAsFixed(1)} km',
                    ),
                    Text('Duration: ${simulatedDurationMin!} min'),
                    Text('Fare: Ksh ${simulatedFare!.toStringAsFixed(2)}'),
                  ],
                  SizedBox(height: 2.h),
                  TextField(
                    controller: pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    onChanged: (_) {
                      setState(updateSimulation);
                    },
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: dropoffController,
                    decoration: const InputDecoration(
                      labelText: 'Drop-off Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    onChanged: (_) {
                      setState(updateSimulation);
                    },
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'M-Pesa Phone Number',
                      hintText: '254XXXXXXXXX or 07XXXXXXXX',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  const Text(
                    'Payment will be processed via M-Pesa. You have 5 minutes to complete payment.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: simulatedFare == null
                    ? null
                    : () => _processBooking(
                          vehicle,
                          user,
                          phoneController.text,
                          pickupController.text,
                          dropoffController.text,
                          simulatedDistanceKm!,
                          simulatedDurationMin!,
                          simulatedFare!,
                        ),
                child: const Text('Pay with M-Pesa'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processBooking(
    Map<String, dynamic> vehicle,
    Map<String, dynamic> user,
    String phoneNumber,
    String pickup,
    String dropoff,
    double simulatedDistanceKm,
    int simulatedDurationMin,
    double fareAmount,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    if (phoneNumber.isEmpty || pickup.isEmpty || dropoff.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create booking record
      final bookingData = {
        'passenger_id': user['id'],
        'vehicle_id': vehicle['id'],
        'status': 'Pending',
        'pickup_location': pickup,
        'dropoff_location': dropoff,
        'fare_amount': fareAmount,
        'seats_booked': 1,
        'simulated_distance_km': simulatedDistanceKm,
        'simulated_duration_min': simulatedDurationMin,
        'final_fare': fareAmount,
      };

      final booking = await _supabase
          .from('Bookings')
          .insert(bookingData)
          .select()
          .single();

      // Initiate M-Pesa payment
      final formattedPhone = MpesaService.formatPhoneNumber(phoneNumber);
      final paymentResult = await MpesaService.initiatePayment(
        bookingId: booking['id'],
        phoneNumber: formattedPhone,
        amount: fareAmount,
      );

      if (!mounted) return;
      navigator.pop(); // Close loading

      if (paymentResult['success']) {
        // Show payment confirmation dialog
        _showPaymentPendingDialog(
          paymentResult['transaction_id'],
          booking['id'],
          formattedPhone,
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(paymentResult['message'])),
        );
      }
    } catch (e) {
      if (!mounted) return;
      navigator.pop(); // Close loading
      messenger.showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  double _randomDistanceKm() {
    return 1 + _random.nextDouble() * 14;
  }

  int _estimateDurationMinutes(double distanceKm) {
    final hours = distanceKm / _avgCitySpeedKph;
    return max(1, (hours * 60).round());
  }

  double _calculateFare(double distanceKm, int durationMin) {
    final fare = _baseFare +
        (distanceKm * _perKmRate) +
        (durationMin * _perMinuteRate);
    return fare < _minimumFare ? _minimumFare : fare;
  }

  void _showPaymentPendingDialog(
    String transactionId,
    String bookingId,
    String phoneNumber,
  ) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    int remainingSeconds = 300; // 5 minutes
    Timer? countdownTimer;
    Timer? statusTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          countdownTimer?.cancel();
          countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              remainingSeconds--;
              if (remainingSeconds <= 0) {
                timer.cancel();
                statusTimer?.cancel();
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Payment timeout. Booking cancelled.'),
                  ),
                );
              }
            });
          });

          statusTimer ??= Timer.periodic(const Duration(seconds: 2), (timer) async {
            final status = await MpesaService.getPaymentStatus(transactionId);
            if (status == 'Completed') {
              timer.cancel();
              countdownTimer?.cancel();
              if (!mounted) return;
              navigator.pop();
              _loadVehicles();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Payment successful! Your booking is confirmed.'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (status == 'Expired') {
              timer.cancel();
              countdownTimer?.cancel();
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Payment expired. Please try again.'),
                ),
              );
            }
          });

          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;

          return AlertDialog(
            title: const Text('Waiting for M-Pesa Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STK push sent to $phoneNumber',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Time remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: remainingSeconds < 60 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                const Text(
                  'Awaiting payment confirmation from M-Pesa sandbox...',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  statusTimer?.cancel();
                  navigator.pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      countdownTimer?.cancel();
      statusTimer?.cancel();
    });
  }
}
