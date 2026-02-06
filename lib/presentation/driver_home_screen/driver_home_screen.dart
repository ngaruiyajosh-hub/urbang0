import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import './widgets/driver_action_button_widget.dart';

/// Driver Home Screen - Central hub for all driver activities
/// Features 4 main action buttons with collapsible content below
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isOnline = false;

  // Track which section is expanded
  String? _expandedSection;

  // Mock stats data
  int _todayTrips = 0;
  double _todayEarnings = 0.0;
  double _driverRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadDriverStats();
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDriverStats() async {
    // Mock data - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _todayTrips = 5;
      _todayEarnings = 125.50;
      _driverRating = 4.8;
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadUserProfile(), _loadDriverStats()]);
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  void _navigateToMore(String category) {
    Navigator.pushNamed(context, AppRoutes.driverMore, arguments: category);
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline ? 'You are now online' : 'You are now offline'),
        duration: const Duration(seconds: 2),
      ),
    );
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
        title: const Text('Driver Dashboard'),
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
                      // Personalized Greeting & Online Status
                      _buildGreetingSection(theme),
                      SizedBox(height: 2.h),

                      // Online/Offline Toggle
                      _buildOnlineStatusToggle(theme),
                      SizedBox(height: 3.h),

                      // Quick Stats Bar
                      _buildQuickStatsBar(theme),
                      SizedBox(height: 3.h),

                      // Main Action Buttons (2x2 Grid)
                      _buildMainActionButtons(theme),
                      SizedBox(height: 2.h),

                      // Collapsible Content Sections
                      _buildCollapsibleSection(
                        theme,
                        'Assigned Bookings',
                        _buildAssignedBookingsContent(theme),
                      ),
                      _buildCollapsibleSection(
                        theme,
                        'Trips',
                        _buildTripsContent(theme),
                      ),
                      _buildCollapsibleSection(
                        theme,
                        'Earnings',
                        _buildEarningsContent(theme),
                      ),
                      _buildCollapsibleSection(
                        theme,
                        'Pick Up/Drop Off Points',
                        _buildPickupDropoffContent(theme),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Emergency support
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency support contacted')),
          );
        },
        tooltip: 'Emergency Support',
        child: const Icon(Icons.emergency),
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
                    _userProfile?['name'] ?? 'Driver',
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
                    icon: Icons.people,
                    title: 'Passengers',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Passengers');
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
                    icon: Icons.route,
                    title: 'Trips',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Trips');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'My Account',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('My Account');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.directions_car,
                    title: 'Vehicle',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Vehicle');
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
                    icon: Icons.music_note,
                    title: 'Entertainment',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Entertainment');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups,
                    title: 'Community',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToMore('Community');
                    },
                  ),
                  Divider(color: theme.dividerColor),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Log Out',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmDialog();
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

  Future<void> _showLogoutConfirmDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
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
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
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
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          _userProfile?['name'] ?? 'Driver',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineStatusToggle(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isOnline
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color:
                  (_isOnline
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline)
                      .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOnline ? Icons.check_circle : Icons.cancel,
              color: _isOnline
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'You are Online' : 'You are Offline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _isOnline
                      ? 'Accepting ride requests'
                      : 'Not accepting requests',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: _isOnline, onChanged: (value) => _toggleOnlineStatus()),
        ],
      ),
    );
  }

  Widget _buildQuickStatsBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            Icons.local_taxi,
            'Today\'s Trips',
            _todayTrips.toString(),
          ),
          Container(
            height: 5.h,
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            theme,
            Icons.attach_money,
            'Earnings',
            'Ksh ${_todayEarnings.toStringAsFixed(2)}',
          ),
          Container(
            height: 5.h,
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            theme,
            Icons.star,
            'Rating',
            _driverRating.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 6.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButtons(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 3.w,
      crossAxisSpacing: 3.w,
      childAspectRatio: 1.0,
      children: [
        DriverActionButtonWidget(
          title: 'Assigned\nBookings',
          subtitle: 'View requests',
          icon: Icons.assignment,
          color: theme.colorScheme.primary,
          onTap: () => _toggleSection('Assigned Bookings'),
        ),
        DriverActionButtonWidget(
          title: 'Trips',
          subtitle: 'Trip history',
          icon: Icons.directions_car,
          color: const Color(0xFF00C851),
          onTap: () => _toggleSection('Trips'),
        ),
        DriverActionButtonWidget(
          title: 'Earnings',
          subtitle: 'Income details',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFFFF8800),
          onTap: () => _toggleSection('Earnings'),
        ),
        DriverActionButtonWidget(
          title: 'Pick Up/\nDrop Off',
          subtitle: 'Route points',
          icon: Icons.location_on,
          color: const Color(0xFFDC3545),
          onTap: () => _toggleSection('Pick Up/Drop Off Points'),
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(title),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 3.w),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildAssignedBookingsContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Ride Requests',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        _buildBookingCard(
          theme,
          'John Doe',
          '123 Main St',
          '456 Oak Ave',
          'Ksh 25.00',
          'driver_assigned',
        ),
        SizedBox(height: 1.h),
        _buildBookingCard(
          theme,
          'Jane Smith',
          '789 Pine Rd',
          '321 Elm St',
          'Ksh 18.50',
          'driver_arriving',
        ),
      ],
    );
  }

  Widget _buildBookingCard(
    ThemeData theme,
    String passengerName,
    String pickup,
    String dropoff,
    String fare,
    String tripStatus,
  ) {
    final driverView = _driverViewForStatus(tripStatus);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 4.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  driverView,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.person, size: 5.w, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  passengerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                fare,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.trip_origin,
                size: 4.w,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  pickup,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 4.w,
                color: theme.colorScheme.error,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  dropoff,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                  child: Text(_actionLabelForStatus(tripStatus)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _driverViewForStatus(String status) {
    switch (status) {
      case 'driver_assigned':
        return 'Assigned - Accept trip';
      case 'driver_arriving':
        return 'Arriving - Navigate to pickup';
      case 'trip_started':
      case 'in_progress':
        return 'Started - Trip in progress';
      case 'completed':
        return 'Completed - Earnings shown';
      default:
        return 'Assigned - Accept trip';
    }
  }

  String _actionLabelForStatus(String status) {
    switch (status) {
      case 'driver_assigned':
        return 'Accept';
      case 'driver_arriving':
        return 'Navigate';
      case 'trip_started':
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Earnings';
      default:
        return 'Accept';
    }
  }

  Widget _buildTripsContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Trips',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        _buildTripCard(
          theme,
          'Trip #1234',
          'Today, 10:30 AM',
          '15.2 km',
          'Ksh 25.00',
          'Completed',
        ),
        SizedBox(height: 1.h),
        _buildTripCard(
          theme,
          'Trip #1233',
          'Today, 9:15 AM',
          '8.5 km',
          'Ksh 18.50',
          'Completed',
        ),
      ],
    );
  }

  Widget _buildTripCard(
    ThemeData theme,
    String tripId,
    String time,
    String distance,
    String fare,
    String status,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tripId,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$time • $distance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            fare,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Summary',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildEarningRow(theme, 'Today', 'Ksh 125.50'),
              Divider(height: 2.h),
              _buildEarningRow(theme, 'This Week', 'Ksh 687.25'),
              Divider(height: 2.h),
              _buildEarningRow(theme, 'This Month', 'Ksh 2,450.00'),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download),
          label: const Text('Download Statement'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 5.h),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningRow(ThemeData theme, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupDropoffContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Route Points',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          height: 25.h,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 15.w, color: theme.colorScheme.outline),
                SizedBox(height: 1.h),
                Text(
                  'No active trip',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Accept a booking to view route',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
