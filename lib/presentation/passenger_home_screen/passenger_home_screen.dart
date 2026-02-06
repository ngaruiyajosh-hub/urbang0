import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/location_simulator_service.dart';
import './widgets/action_button_widget.dart';

/// Passenger Home Screen - Central hub for all passenger activities
/// Features 4 main action buttons with collapsible content below
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  // Track which section is expanded
  String? _expandedSection;

  // Driver tracking state
  final LocationSimulatorService _locationService = LocationSimulatorService();
  StreamSubscription<DriverLocation>? _locationSubscription;
  DriverLocation? _currentLocation;
  String? _expandedRideSubsection;
  Map<String, dynamic>? _activeBookingForTracking;
  String _tripStatus = 'driver_assigned';
  final Map<String, int> _rideRatings = {};
  final List<Map<String, String>> _ridesToRate = [
    {
      'id': 'ride_1',
      'route': 'Downtown to Airport',
      'driver': 'John Doe',
      'vehicle': 'Toyota Prius - KCA 123X',
      'date': 'Jan 15, 2026',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.id);
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      } else {
        // User is null - set loading to false to show content
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadUserProfile();
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
      // Reset ride subsection when collapsing Rides
      if (_expandedSection != 'Rides') {
        _expandedRideSubsection = null;
        _stopTracking();
      }
    });
  }

  void _toggleRideSubsection(String subsection) {
    setState(() {
      if (_expandedRideSubsection == subsection) {
        _expandedRideSubsection = null;
        _stopTracking();
      } else {
        _expandedRideSubsection = subsection;
        if (subsection == 'Driver Tracking' &&
            _activeBookingForTracking != null) {
          _startTracking(_activeBookingForTracking!);
        }
      }
    });
  }

  void _startTracking(Map<String, dynamic> booking) {
    _activeBookingForTracking = booking;
    _tripStatus = (booking['trip_status'] ?? booking['status'] ?? 'driver_assigned')
        .toString()
        .toLowerCase();
    // Destination (passenger pickup location in Nairobi)
    final double pickupLat = -1.2921;
    final double pickupLng = 36.8219;

    if (_tripStatus == 'driver_arriving' || _tripStatus == 'in_progress') {
      _locationService.startSimulation(
        destinationLat: pickupLat,
        destinationLng: pickupLng,
      );
    }

    _locationSubscription = _locationService.locationStream.listen((location) {
      if (mounted) {
        setState(() {
          _currentLocation = location;
        });
      }
    });
  }

  void _stopTracking() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    setState(() {
      _currentLocation = null;
      _activeBookingForTracking = null;
    });
  }

  void _navigateToMore(String category) {
    Navigator.pushNamed(context, AppRoutes.more, arguments: category);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Menu',
          ),
        ),
        title: const Text('Urban Go'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: _buildDrawer(theme),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personalized Greeting Section
                      _buildGreetingSection(theme),
                      SizedBox(height: 3.h),

                      // Main Action Buttons (2x2 Grid)
                      _buildMainActionButtons(theme),
                      SizedBox(height: 2.h),

                      // Collapsible Content Sections
                      _buildCollapsibleSection(
                        theme,
                        'Book a Ride',
                        _buildBookRideContent(theme),
                      ),
                      _buildCollapsibleSection(
                        theme,
                        'Rides',
                        _buildMyRidesContent(theme),
                      ),
                      _buildCollapsibleSection(
                        theme,
                        'Payment',
                        _buildPaymentContent(theme),
                      ),
                      _buildCollapsibleSection(
                        theme,
                        'Rate & Review',
                        _buildRatingContent(theme),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10.w,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 10.w,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _userProfile?['name'] ?? 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _userProfile?['email'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                children: [
                  _buildDrawerItem(
                    icon: Icons.payment,
                    title: 'Payment',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Payment');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet,
                    title: 'My Wallet',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('My Wallet');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.directions_car,
                    title: 'Available Rides',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Available Rides');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'My account',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('My account');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.support_agent,
                    title: 'Support',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Support');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.movie,
                    title: 'Entertainment',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Entertainment');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'Community',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Community');
                    },
                  ),
                  Divider(color: theme.dividerColor),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to sign out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (!mounted) return;
                      if (shouldLogout == true) {
                        await _authService.signOut();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Widget _buildGreetingSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 8.w,
            backgroundColor: Colors.white,
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
                  'Hello, ${_userProfile?['name'] ?? 'User'}!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Where would you like to go?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButtons(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 3.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.2,
      children: [
        ActionButtonWidget(
          icon: Icons.directions_car,
          title: 'Book a Ride',
          subtitle: 'Find your ride',
          color: const Color(0xFF2196F3),
          onTap: () => _toggleSection('Book a Ride'),
        ),
        ActionButtonWidget(
          icon: Icons.history,
          title: 'Rides',
          subtitle: 'View & track',
          color: const Color(0xFF4CAF50),
          onTap: () => _toggleSection('Rides'),
        ),
        ActionButtonWidget(
          icon: Icons.payment,
          title: 'Payment',
          subtitle: 'Manage payments',
          color: const Color(0xFFFF9800),
          onTap: () => _toggleSection('Payment'),
        ),
        ActionButtonWidget(
          icon: Icons.star_rate,
          title: 'Rate & Review',
          subtitle: 'Share feedback',
          color: const Color(0xFF9C27B0),
          onTap: () => _toggleSection('Rate & Review'),
        ),
      ],
    );
  }

  Widget _buildCollapsibleSection(
    ThemeData theme,
    String title,
    Widget content,
  ) {
    final isExpanded = _expandedSection == title;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isExpanded
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.2),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isExpanded ? theme.colorScheme.primary : null,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isExpanded ? theme.colorScheme.primary : null,
            ),
            onTap: () => _toggleSection(title),
          ),
          if (isExpanded) Padding(padding: EdgeInsets.all(4.w), child: content),
        ],
      ),
    );
  }

  Widget _buildBookRideContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Pickup location',
            prefixIcon: const Icon(Icons.my_location),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        TextField(
          decoration: InputDecoration(
            hintText: 'Drop-off location',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Searching for rides...')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(
            'Find Ride',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRidesContent(ThemeData theme) {
    return Column(
      children: [
        // Driver Tracking Subsection
        _buildRideSubsection(
          theme,
          'Driver Tracking',
          Icons.my_location,
          _buildDriverTrackingContent(theme),
        ),
        SizedBox(height: 1.h),
        // Ride History Subsection
        _buildRideSubsection(
          theme,
          'Ride History',
          Icons.history,
          _buildRideHistoryContent(theme),
        ),
      ],
    );
  }

  Widget _buildRideSubsection(
    ThemeData theme,
    String title,
    IconData icon,
    Widget content,
  ) {
    final isExpanded = _expandedRideSubsection == title;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () => _toggleRideSubsection(title),
          ),
          if (isExpanded) Padding(padding: EdgeInsets.all(3.w), child: content),
        ],
      ),
    );
  }

  Widget _buildDriverTrackingContent(ThemeData theme) {
    // Mock active booking - in real app, fetch from Supabase
    final mockBooking = {
      'id': 'booking-123',
      'pickup_location': 'Westlands, Nairobi',
      'dropoff_location': 'CBD, Nairobi',
      'fare_amount': 450.0,
      'status': 'Confirmed',
      'trip_status': 'driver_arriving',
      'Vehicle': {
        'vehicle_type': 'Sedan',
        'license_plate': 'KCA 123X',
        'User': {'name': 'John Driver'},
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Tracking Button
        if (_currentLocation == null)
          ElevatedButton.icon(
            onPressed: () {
              _startTracking(mockBooking);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 5.h),
            ),
          ),
        if (_currentLocation != null) ...[
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
                    _passengerMessageForStatus(_tripStatus),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ETA Banner
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

          // Map View (Simulated)
          Container(
            height: 25.h,
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 15.w,
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Nairobi, Kenya',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10.h,
                  left: 40.w,
                  child: Icon(Icons.location_on, color: Colors.red, size: 8.w),
                ),
              ],
            ),
          ),

          // Driver Info
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 6.w,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 6.w,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (mockBooking['Vehicle']
                                as Map<String, dynamic>)['User']['name']
                            as String,
                        style: theme.textTheme.bodyLarge?.copyWith(
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
                            '${(mockBooking['Vehicle'] as Map<String, dynamic>)['vehicle_type']} • ${(mockBooking['Vehicle'] as Map<String, dynamic>)['license_plate']}',
                            style: theme.textTheme.bodySmall?.copyWith(
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
          ),

          SizedBox(height: 2.h),

          // Trip Details
          _buildTripDetail(
            theme,
            Icons.location_on,
            'Pickup',
            mockBooking['pickup_location'] as String,
          ),
          SizedBox(height: 1.h),
          _buildTripDetail(
            theme,
            Icons.flag,
            'Drop-off',
            mockBooking['dropoff_location'] as String,
          ),

          SizedBox(height: 2.h),

          // Stop Tracking Button
          OutlinedButton.icon(
            onPressed: _stopTracking,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Tracking'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: Size(double.infinity, 5.h),
            ),
          ),
        ],
      ],
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
        Icon(icon, size: 5.w, color: theme.colorScheme.primary),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideHistoryContent(ThemeData theme) {
    return Column(
      children: [
        _buildRideItem(
          theme,
          'Downtown to Airport',
          'Completed - Jan 15, 2026',
          Icons.check_circle,
          Colors.green,
        ),
        SizedBox(height: 1.h),
        _buildRideItem(
          theme,
          'Home to Office',
          'Completed - Jan 10, 2026',
          Icons.check_circle,
          Colors.green,
        ),
        SizedBox(height: 1.h),
        _buildRideItem(
          theme,
          'Mall to Restaurant',
          'Cancelled - Jan 5, 2026',
          Icons.cancel,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildRideItem(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent(ThemeData theme) {
    return Column(
      children: [
        _buildPaymentMethod(
          theme,
          'Credit Card',
          '**** **** **** 1234',
          Icons.credit_card,
          true,
        ),
        SizedBox(height: 1.h),
        _buildPaymentMethod(
          theme,
          'PayPal',
          'user@example.com',
          Icons.account_balance_wallet,
          false,
        ),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add payment method...')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Payment Method'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool isDefault,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
        border: isDefault
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                'Default',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingContent(ThemeData theme) {
    final lastRide = _ridesToRate.first;
    return Column(
      children: [
        Text(
          'Rate your last ride',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        _buildRatingItem(
          theme,
          rideId: lastRide['id'] ?? '',
          title: lastRide['route'] ?? '',
          driverName: lastRide['driver'] ?? '',
          vehicle: lastRide['vehicle'] ?? '',
          date: lastRide['date'] ?? '',
        ),
      ],
    );
  }

  Widget _buildRatingItem(
    ThemeData theme, {
    required String rideId,
    required String title,
    required String driverName,
    required String vehicle,
    required String date,
  }) {
    final rating = _rideRatings[rideId] ?? 0;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Driver: $driverName',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            vehicle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Date: $date',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) {
                final isSelected = index < rating;
                return IconButton(
                  icon: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => _setRideRating(rideId, index + 1),
                );
              },
            ),
          ),
          Center(
            child: Text(
              rating == 0 ? 'Tap to rate' : 'You rated $rating of 5',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setRideRating(String rideId, int rating) {
    setState(() {
      _rideRatings[rideId] = rating;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rated $rating star${rating == 1 ? '' : 's'}')),
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
