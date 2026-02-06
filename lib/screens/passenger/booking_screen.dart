import 'package:flutter/material.dart';
import 'package:urban_go/models/vehicle_model.dart';
import 'package:urban_go/services/auth_service.dart';
import 'package:urban_go/services/booking_service.dart';
import 'package:urban_go/services/vehicle_service.dart';
import 'package:urban_go/services/pricing_service.dart';
import 'package:urban_go/services/gps_service.dart';
import 'package:urban_go/services/payment_service.dart';

class BookingScreen extends StatefulWidget {
  final Vehicle vehicle;
  final String pickupLocation;
  final String dropLocation;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;

  const BookingScreen({
    super.key,
    required this.vehicle,
    required this.pickupLocation,
    required this.dropLocation,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late int _seatsSelected = 1;
  String _paymentMethod = 'digital';
  bool _isProcessing = false;

  late double _calculatedFare;

  @override
  void initState() {
    super.initState();
    _calculateFare();
  }

  void _calculateFare() {
    if (widget.pickupLat != null && widget.pickupLng != null && widget.dropLat != null && widget.dropLng != null) {
      final distance = PricingService.distanceBetween(
        widget.pickupLat!,
        widget.pickupLng!,
        widget.dropLat!,
        widget.dropLng!,
      );
      _calculatedFare = PricingService.calculateFare(distance, widget.vehicle.pricePerKm, _seatsSelected);
    } else {
      // Fallback to a simple estimate (10 km)
      const distance = 10.0;
      _calculatedFare = widget.vehicle.pricePerKm * distance * _seatsSelected;
    }
  }

  void _handleBooking() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }
        // If digital payment, initiate M-Pesa STK Push
        if (_paymentMethod == 'digital') {
          final phone = user.phone;
          final amt = _calculatedFare;
          final resp = await PaymentService.initiateMpesaStkPush(
            phone: phone,
            amount: amt,
            accountReference: 'UrbanGoBooking',
          );
          // In real integration verify with checkoutRequestId
          final checkoutId = resp['checkoutRequestId'];
          final verified = await PaymentService.verifyTransaction(checkoutId);
          if (!verified) {
            throw Exception('Payment failed');
          }
        }

        // Create booking (fare computed server-side in BookingService when coords provided)
        final bookingId = await BookingService.createBooking(
          passengerId: user.id,
          vehicleId: widget.vehicle.id,
          pickupLocation: widget.pickupLocation,
          dropLocation: widget.dropLocation,
          pickupLat: widget.pickupLat,
          pickupLng: widget.pickupLng,
          dropLat: widget.dropLat,
          dropLng: widget.dropLng,
          seatsBooked: _seatsSelected,
          paymentMethod: _paymentMethod,
        );

      if (bookingId != null) {
        // Book seats in vehicle
        await VehicleService.bookSeats(
          vehicleId: widget.vehicle.id,
          seatsToBook: _seatsSelected,
          passengerId: user.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking confirmed!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Journey details card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journey Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildJourneyRow(
                        'From',
                        widget.pickupLocation.isEmpty
                            ? widget.vehicle.currentRoute.split(':')[0]
                            : widget.pickupLocation,
                      ),
                      const SizedBox(height: 12),
                      _buildJourneyRow(
                        'To',
                        widget.dropLocation.isEmpty
                            ? 'Destination'
                            : widget.dropLocation,
                      ),
                      const SizedBox(height: 12),
                      _buildJourneyRow(
                        'Vehicle',
                        widget.vehicle.registrationNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildJourneyRow(
                        'Route',
                        widget.vehicle.currentRoute,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Seat selection
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number of Seats',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _seatsSelected > 1
                                ? () {
                                    setState(() {
                                      _seatsSelected--;
                                      _calculateFare();
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle),
                            iconSize: 32,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_seatsSelected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _seatsSelected < widget.vehicle.availableSeats
                                ? () {
                                    setState(() {
                                      _seatsSelected++;
                                      _calculateFare();
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.add_circle),
                            iconSize: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.vehicle.availableSeats} seats available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Payment method
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<String>(
                        title: const Text('Digital Payment'),
                        value: 'digital',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Pay on Boarding'),
                        value: 'cash',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Fare summary
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Base Fare:'),
                          Text(
                            '₹${(widget.vehicle.pricePerKm * 10).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Seats:'),
                          Text('$_seatsSelected'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Fare:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${_calculatedFare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleBooking,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm & Book'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
