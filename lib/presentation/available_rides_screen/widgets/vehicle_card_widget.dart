import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Vehicle Card Widget - Displays vehicle details with booking option
class VehicleCardWidget extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onBook;

  const VehicleCardWidget({
    super.key,
    required this.vehicle,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driverName = vehicle['User']?['name'] ?? 'Unknown Driver';
    final vehicleType = vehicle['vehicle_type'] ?? 'Unknown';
    final licensePlate = vehicle['license_plate'] ?? 'N/A';
    final availableSeats = vehicle['available_seats'] ?? 0;
    final capacity = vehicle['capacity'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: theme.colorScheme.primary,
                  size: 8.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleType,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      driverName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: availableSeats > 0
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '$availableSeats/$capacity seats',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: availableSeats > 0
                        ? const Color(0xFF4CAF50)
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(
                Icons.confirmation_number,
                size: 4.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(licensePlate, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Icon(Icons.star, size: 4.w, color: const Color(0xFFFFC107)),
              SizedBox(width: 1.w),
              Text(
                '4.8',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // View details
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: availableSeats > 0 ? onBook : null,
                  icon: const Icon(Icons.check_circle),
                  label: Text(availableSeats > 0 ? 'Book Now' : 'Full'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: availableSeats > 0
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
