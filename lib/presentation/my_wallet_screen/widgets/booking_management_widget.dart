import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BookingManagementWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final Function(String) onCancelBooking;
  final VoidCallback onRefresh;

  const BookingManagementWidget({
    super.key,
    required this.bookings,
    required this.onCancelBooking,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmedBookings = bookings
        .where((b) => b['status'] == 'Confirmed')
        .toList();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Bookings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
            ],
          ),
          SizedBox(height: 2.h),
          if (confirmedBookings.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 12.w,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No active bookings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...confirmedBookings.map(
              (booking) => _buildBookingCard(context, booking),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final theme = Theme.of(context);
    final vehicleData = booking['Vehicle'] ?? {};
    final fareAmount = (booking['fare_amount'] ?? 0.0).toDouble();
    final lifecycle = _buildTripLifecycle(booking);
    final tripStatus = lifecycle.currentStatusLabel;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleData['vehicle_type'] ?? 'Vehicle',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      vehicleData['license_plate'] ?? 'N/A',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Confirmed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.timeline,
                size: 4.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 1.w),
              Text(
                'Trip status:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  tripStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildLifecycleTimeline(theme, lifecycle),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 4.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  booking['pickup_location'] ?? 'Pickup location',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(
                Icons.flag,
                size: 4.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  booking['dropoff_location'] ?? 'Drop-off location',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fare: Ksh ${fareAmount.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showCancelConfirmation(context, booking),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  _TripLifecycle _buildTripLifecycle(Map<String, dynamic> booking) {
    final steps = <_TripLifecycleStep>[
      _TripLifecycleStep('Booking Confirmed', Icons.check_circle),
      _TripLifecycleStep('Driver Assigned', Icons.person_pin_circle),
      _TripLifecycleStep('Driver En Route', Icons.directions_car),
      _TripLifecycleStep('Arrived at Pickup', Icons.location_on),
      _TripLifecycleStep('Trip Started', Icons.play_circle_fill),
      _TripLifecycleStep('Trip Completed', Icons.flag),
    ];

    final status = (booking['trip_status'] ?? booking['status'] ?? '')
        .toString()
        .toLowerCase();

    final currentIndex = _indexForStatus(status);

    return _TripLifecycle(steps: steps, currentIndex: currentIndex);
  }

  int _indexForStatus(String status) {
    switch (status) {
      case 'driver_assigned':
        return 1;
      case 'driver_arriving':
        return 2;
      case 'trip_started':
        return 4;
      case 'in_progress':
        return 4;
      case 'completed':
        return 5;
      default:
        return 0;
    }
  }

  Widget _buildLifecycleTimeline(ThemeData theme, _TripLifecycle lifecycle) {
    return Column(
      children: List.generate(lifecycle.steps.length, (index) {
        final step = lifecycle.steps[index];
        final isCompleted = index <= lifecycle.currentIndex;
        final color = isCompleted
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

        return Padding(
          padding: EdgeInsets.only(bottom: index == lifecycle.steps.length - 1 ? 0 : 1.h),
          child: Row(
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color),
                ),
                child: Icon(step.icon, size: 3.5.w, color: color),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  step.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight:
                        index == lifecycle.currentIndex ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final fareAmount = (booking['fare_amount'] ?? 0.0).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel this booking?\n\nKsh ${fareAmount.toStringAsFixed(2)} will be refunded to your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onCancelBooking(booking['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _TripLifecycleStep {
  final String label;
  final IconData icon;

  _TripLifecycleStep(this.label, this.icon);
}

class _TripLifecycle {
  final List<_TripLifecycleStep> steps;
  final int currentIndex;

  _TripLifecycle({required this.steps, required this.currentIndex});

  String get currentStatusLabel => steps[currentIndex].label;
}
