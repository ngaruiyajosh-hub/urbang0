import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../my_wallet_screen/widgets/balance_card_widget.dart';
import '../my_wallet_screen/widgets/quick_action_button.dart';
import '../my_wallet_screen/widgets/transaction_item_widget.dart';

class DriverMoreScreen extends StatefulWidget {
  const DriverMoreScreen({super.key});

  @override
  State<DriverMoreScreen> createState() => _DriverMoreScreenState();
}

class _DriverMoreScreenState extends State<DriverMoreScreen> {
  final _authService = AuthService();
  String? _expandedCategory;
  bool _didAutoExpandCategory = false;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = false;
  Uint8List? _profileImageBytes;
  final Map<String, dynamic> _conductorProfile = {
    'name': 'Samuel Njoroge',
    'phone': '+254 700 000 000',
    'rating': 4.7,
    'completedTrips': 124,
  };
  Timer? _nowPlayingTimer;
  int _nowPlayingElapsedSeconds = 0;
  final int _nowPlayingDurationSeconds = 225;
  final bool _isNowPlaying = true;

  final bool _isRefreshing = false;
  String _selectedTransactionFilter = 'All';
  final List<String> _transactionFilters = [
    'All',
    'Earnings',
    'Payouts',
    'Bonuses',
  ];

  List<Map<String, dynamic>> _passengers = [];
  bool _isLoadingPassengers = false;

  List<Map<String, dynamic>> _trips = [];
  bool _isLoadingTrips = false;
  String _selectedTripFilter = 'All';
  final List<String> _tripFilters = ['All', 'Completed', 'Cancelled', 'Today'];

  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoadingVehicles = false;

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'txn_1',
      'type': 'earning',
      'description': 'Trip to Downtown',
      'amount': 45.50,
      'date': '2026-02-04 14:30',
      'status': 'completed',
      'icon': Icons.attach_money,
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'txn_2',
      'type': 'payout',
      'description': 'Weekly Payout',
      'amount': -320.00,
      'date': '2026-02-03 10:15',
      'status': 'completed',
      'icon': Icons.account_balance,
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'txn_3',
      'type': 'earning',
      'description': 'Trip to Airport',
      'amount': 78.25,
      'date': '2026-02-02 08:45',
      'status': 'completed',
      'icon': Icons.attach_money,
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'txn_4',
      'type': 'bonus',
      'description': 'Peak Hour Bonus',
      'amount': 25.00,
      'date': '2026-02-01 16:20',
      'status': 'completed',
      'icon': Icons.star,
      'color': Color(0xFFFF9800),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startNowPlayingTimer();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nowPlayingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    setState(() => _isLoadingProfile = true);
    final profile = await _authService.getUserProfile(user.id);
    if (!mounted) return;
    setState(() {
      _userProfile = profile ?? {};
      _isLoadingProfile = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _profileImageBytes = bytes;
    });
  }

  void _startNowPlayingTimer() {
    _nowPlayingTimer?.cancel();
    _nowPlayingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isNowPlaying) return;
      setState(() {
        _nowPlayingElapsedSeconds =
            (_nowPlayingElapsedSeconds + 1) % _nowPlayingDurationSeconds;
      });
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategory == category) {
        _expandedCategory = null;
      } else {
        _expandedCategory = category;
        if (category == 'Passengers' && _passengers.isEmpty) {
          _loadPassengers();
        } else if (category == 'Trips' && _trips.isEmpty) {
          _loadTrips();
        } else if (category == 'Vehicle' && _vehicles.isEmpty) {
          _loadVehicles();
        }
      }
    });
  }

  Future<void> _loadPassengers() async {
    try {
      setState(() => _isLoadingPassengers = true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _passengers = [
          {
            'id': 'p1',
            'name': 'John Smith',
            'rating': 4.8,
            'trips': 12,
            'lastRide': '2026-02-04',
            'avatar': 'https://i.pravatar.cc/150?img=1',
          },
          {
            'id': 'p2',
            'name': 'Sarah Johnson',
            'rating': 5.0,
            'trips': 8,
            'lastRide': '2026-02-03',
            'avatar': 'https://i.pravatar.cc/150?img=2',
          },
          {
            'id': 'p3',
            'name': 'Michael Brown',
            'rating': 4.5,
            'trips': 15,
            'lastRide': '2026-02-02',
            'avatar': 'https://i.pravatar.cc/150?img=3',
          },
        ];
        _isLoadingPassengers = false;
      });
    } catch (e) {
      debugPrint('Error loading passengers: $e');
      setState(() => _isLoadingPassengers = false);
    }
  }

  Future<void> _loadTrips() async {
    try {
      setState(() => _isLoadingTrips = true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _trips = [
          {
            'id': 't1',
            'passenger': 'John Smith',
            'pickup': '123 Main St',
            'dropoff': 'Downtown Plaza',
            'fare': 45.50,
            'distance': '12.5 km',
            'duration': '25 min',
            'status': 'completed',
            'date': '2026-02-04 14:30',
          },
          {
            'id': 't2',
            'passenger': 'Sarah Johnson',
            'pickup': '456 Oak Ave',
            'dropoff': 'Airport Terminal 2',
            'fare': 78.25,
            'distance': '28.3 km',
            'duration': '45 min',
            'status': 'completed',
            'date': '2026-02-04 10:15',
          },
          {
            'id': 't3',
            'passenger': 'Michael Brown',
            'pickup': '789 Pine Rd',
            'dropoff': 'Shopping Mall',
            'fare': 32.00,
            'distance': '8.7 km',
            'duration': '18 min',
            'status': 'cancelled',
            'date': '2026-02-03 16:45',
          },
        ];
        _isLoadingTrips = false;
      });
    } catch (e) {
      debugPrint('Error loading trips: $e');
      setState(() => _isLoadingTrips = false);
    }
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() => _isLoadingVehicles = true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _vehicles = [
          {
            'id': 'v1',
            'make': 'Toyota',
            'model': 'Camry',
            'year': 2022,
            'plate': 'ABC-1234',
            'color': 'Silver',
            'type': 'Economy',
            'status': 'Active',
            'insurance_expiry': '2026-12-31',
            'last_service': '2026-01-15',
          },
        ];
        _isLoadingVehicles = false;
      });
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
      setState(() => _isLoadingVehicles = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedTransactionFilter == 'All') return _transactions;
    return _transactions.where((txn) {
      switch (_selectedTransactionFilter) {
        case 'Earnings':
          return txn['type'] == 'earning';
        case 'Payouts':
          return txn['type'] == 'payout';
        case 'Bonuses':
          return txn['type'] == 'bonus';
        default:
          return true;
      }
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredTrips {
    if (_selectedTripFilter == 'All') return _trips;
    return _trips.where((trip) {
      switch (_selectedTripFilter) {
        case 'Completed':
          return trip['status'] == 'completed';
        case 'Cancelled':
          return trip['status'] == 'cancelled';
        case 'Today':
          return trip['date'].startsWith('2026-02-04');
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  Future<void> _launchAppOrWeb({
    required Uri appUri,
    required Uri webUri,
  }) async {
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openSpotify() async {
    await _launchAppOrWeb(
      appUri: Uri.parse('spotify://'),
      webUri: Uri.parse('https://open.spotify.com'),
    );
  }

  Future<void> _openYouTube() async {
    await _launchAppOrWeb(
      appUri: Uri.parse('vnd.youtube://'),
      webUri: Uri.parse('https://www.youtube.com'),
    );
  }

  Future<void> _openStandardMedia() async {
    await launchUrl(
      Uri.parse('https://www.standardmedia.co.ke'),
      mode: LaunchMode.externalApplication,
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _selectCategoryFromDrawer(String category) {
    Navigator.pop(context);
    _toggleCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String? selectedCategory =
        ModalRoute.of(context)?.settings.arguments as String?;

    if (selectedCategory != null && !_didAutoExpandCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _expandedCategory = selectedCategory;
          _didAutoExpandCategory = true;
          if (selectedCategory == 'Passengers' && _passengers.isEmpty) {
            _loadPassengers();
          } else if (selectedCategory == 'Trips' && _trips.isEmpty) {
            _loadTrips();
          } else if (selectedCategory == 'Vehicle' && _vehicles.isEmpty) {
            _loadVehicles();
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('More'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      drawer: _buildDrawer(theme),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Manage your driver account and preferences',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 3.h),

              _buildCollapsibleCategory(
                theme,
                'Passengers',
                Icons.people,
                const Color(0xFF2196F3),
                _buildPassengersContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'My Wallet',
                Icons.account_balance_wallet,
                const Color(0xFF4CAF50),
                _buildWalletContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'Trips',
                Icons.route,
                const Color(0xFFFF9800),
                _buildTripsContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'My Account',
                Icons.person,
                const Color(0xFF9C27B0),
                _buildAccountContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'Vehicle',
                Icons.directions_car,
                const Color(0xFF00BCD4),
                _buildVehicleContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'Support',
                Icons.support_agent,
                const Color(0xFFF44336),
                _buildSupportContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'Entertainment',
                Icons.music_note,
                const Color(0xFFE91E63),
                _buildEntertainmentContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'Community',
                Icons.groups,
                const Color(0xFF673AB7),
                _buildCommunityContent(theme),
              ),
              SizedBox(height: 1.5.h),

              _buildCollapsibleCategory(
                theme,
                'Log Out',
                Icons.logout,
                const Color(0xFFF44336),
                _buildLogoutContent(theme),
              ),
              SizedBox(height: 2.h),
            ],
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
                  Text(
                    'Driver Menu',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                children: [
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'Passengers',
                    onTap: () => _selectCategoryFromDrawer('Passengers'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet,
                    title: 'My Wallet',
                    onTap: () => _selectCategoryFromDrawer('My Wallet'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.route,
                    title: 'Trips',
                    onTap: () => _selectCategoryFromDrawer('Trips'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'My Account',
                    onTap: () => _selectCategoryFromDrawer('My Account'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.directions_car,
                    title: 'Vehicle',
                    onTap: () => _selectCategoryFromDrawer('Vehicle'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.support_agent,
                    title: 'Support',
                    onTap: () => _selectCategoryFromDrawer('Support'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.music_note,
                    title: 'Entertainment',
                    onTap: () => _selectCategoryFromDrawer('Entertainment'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups,
                    title: 'Community',
                    onTap: () => _selectCategoryFromDrawer('Community'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Log Out',
                    onTap: () => _selectCategoryFromDrawer('Log Out'),
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

  Widget _buildCollapsibleCategory(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    final isExpanded = _expandedCategory == title;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 6.w),
            ),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
            ),
            onTap: () => _toggleCategory(title),
          ),
          if (isExpanded) Padding(padding: EdgeInsets.all(4.w), child: content),
        ],
      ),
    );
  }

  Widget _buildPassengersContent(ThemeData theme) {
    if (_isLoadingPassengers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Passengers',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ..._passengers.map(
          (passenger) => _buildPassengerCard(theme, passenger),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.star),
                label: const Text('Rate Passengers'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.feedback),
                label: const Text('Feedback'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPassengerCard(ThemeData theme, Map<String, dynamic> passenger) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(passenger['avatar']),
          radius: 6.w,
        ),
        title: Text(
          passenger['name'],
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${passenger['trips']} trips • Last ride: ${passenger['lastRide']}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 4.w),
            SizedBox(width: 1.w),
            Text(
              passenger['rating'].toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BalanceCardWidget(
          balance: 1245.75,
          isRefreshing: _isRefreshing,
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.account_balance,
                label: 'Payout',
                color: const Color(0xFF2196F3),
                onTap: () {},
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: QuickActionButton(
                icon: Icons.history,
                label: 'History',
                color: const Color(0xFF4CAF50),
                onTap: () {},
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: QuickActionButton(
                icon: Icons.analytics,
                label: 'Analytics',
                color: const Color(0xFFFF9800),
                onTap: () {},
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Text(
              'Transactions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedTransactionFilter,
              underline: const SizedBox(),
              items: _transactionFilters.map((filter) {
                return DropdownMenuItem(value: filter, child: Text(filter));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTransactionFilter = value);
                }
              },
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ..._filteredTransactions.map(
          (txn) => TransactionItemWidget(
            transaction: txn,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTripsContent(ThemeData theme) {
    if (_isLoadingTrips) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Trip History',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedTripFilter,
              underline: const SizedBox(),
              items: _tripFilters.map((filter) {
                return DropdownMenuItem(value: filter, child: Text(filter));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTripFilter = value);
                }
              },
            ),
          ],
        ),
        SizedBox(height: 2.h),
        ..._filteredTrips.map((trip) => _buildTripCard(theme, trip)),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.analytics),
                label: const Text('Performance'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bar_chart),
                label: const Text('Analytics'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripCard(ThemeData theme, Map<String, dynamic> trip) {
    final isCompleted = trip['status'] == 'completed';
    final statusColor = isCompleted
        ? const Color(0xFF4CAF50)
        : const Color(0xFFF44336);

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip['passenger'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    trip['status'].toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.location_on, size: 4.w, color: Colors.grey[600]),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(trip['pickup'], style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.flag, size: 4.w, color: Colors.grey[600]),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    trip['dropoff'],
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${trip['distance']} • ${trip['duration']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Ksh ${trip['fare'].toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAccountSection(
          theme,
          title: 'Profile Information',
          icon: Icons.person_outline,
          child: _buildDriverProfileInfo(theme),
        ),
        SizedBox(height: 1.h),
        _buildAccountSection(
          theme,
          title: 'Documents',
          icon: Icons.description,
          child: _buildDriverDocuments(theme),
        ),
        SizedBox(height: 1.h),
        _buildAccountSection(
          theme,
          title: 'Verification Status',
          icon: Icons.verified,
          child: _buildVerificationStatus(theme),
        ),
        SizedBox(height: 1.h),
        _buildAccountSection(
          theme,
          title: 'Account History',
          icon: Icons.history,
          child: _buildAccountHistory(theme),
        ),
        SizedBox(height: 1.h),
        _buildAccountSection(
          theme,
          title: 'Common Routes',
          icon: Icons.route,
          child: _buildCommonRoutes(theme),
        ),
        SizedBox(height: 1.h),
        _buildAccountSection(
          theme,
          title: 'Preferences',
          icon: Icons.settings,
          child: _buildPreferences(theme),
        ),
      ],
    );
  }

  Widget _buildAccountSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: EdgeInsets.all(3.w),
        children: [child],
      ),
    );
  }

  Widget _buildDriverProfileInfo(ThemeData theme) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = _userProfile?['name'] ?? 'Driver';
    final email = _userProfile?['email'] ?? '';
    final phone = _userProfile?['phone number'] ?? _userProfile?['phone'] ?? '';
    final address = _userProfile?['home_address'] ?? 'Nairobi, Kenya';
    final license = _userProfile?['license'] ?? 'DL-DR-001239';
    final rating = (_userProfile?['rating'] ?? 4.8).toDouble();

    Widget avatar;
    if (_profileImageBytes != null) {
      avatar = CircleAvatar(
        radius: 8.w,
        backgroundImage: MemoryImage(_profileImageBytes!),
      );
    } else {
      avatar = CircleAvatar(
        radius: 8.w,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          Icons.person,
          size: 8.w,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            avatar,
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.6.h),
                  _buildRatingRow(theme, rating),
                ],
              ),
            ),
            TextButton(
              onPressed: _pickProfileImage,
              child: const Text('Change Photo'),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildInfoRow(theme, 'Home Address', address),
        _buildInfoRow(theme, 'Email', email),
        _buildInfoRow(theme, 'Phone', phone),
        _buildInfoRow(theme, 'License', license),
        SizedBox(height: 2.h),
        Text(
          'Conductor Profile',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        _buildInfoRow(theme, 'Name', _conductorProfile['name']),
        _buildInfoRow(theme, 'Phone', _conductorProfile['phone']),
        Row(
          children: [
            Text(
              'Rating',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            _buildRatingStars(
              theme,
              (_conductorProfile['rating'] as num).toDouble(),
            ),
            SizedBox(width: 2.w),
            Text(
              (_conductorProfile['rating'] as num).toStringAsFixed(1),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.8.h),
        _buildInfoRow(
          theme,
          'Completed Trips',
          _conductorProfile['completedTrips'].toString(),
        ),
      ],
    );
  }

  Widget _buildDriverDocuments(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(theme, 'Driver License', 'Valid until 2027-10-15'),
        _buildInfoRow(theme, 'Vehicle Insurance', 'Valid until 2026-08-20'),
        _buildInfoRow(theme, 'PSV Badge', 'Valid until 2026-05-12'),
        SizedBox(height: 1.h),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Document'),
        ),
      ],
    );
  }

  Widget _buildVerificationStatus(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(theme, 'Identity', true),
        _buildStatusRow(theme, 'License', true),
        _buildStatusRow(theme, 'Vehicle Inspection', true),
        _buildStatusRow(theme, 'Insurance', false),
      ],
    );
  }

  Widget _buildAccountHistory(ThemeData theme) {
    final history = [
      'Joined Urban Go - 2024-03-14',
      'Completed 500 trips - 2025-11-02',
      'Received 5-star rating - 2026-01-21',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: history
          .map(
            (item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.6.h),
              child: Text(item, style: theme.textTheme.bodySmall),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCommonRoutes(ThemeData theme) {
    final routes = [
      'Route 24 Westlands',
      'Route 18 Airport Express',
      'Route 11 Rongai',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: routes
          .map(
            (route) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.6.h),
              child: Text(route, style: theme.textTheme.bodySmall),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPreferences(ThemeData theme) {
    final isDark = ThemeService.themeMode.value == ThemeMode.dark;
    return Column(
      children: [
        SwitchListTile(
          value: isDark,
          onChanged: (value) {
            ThemeService.setTheme(value ? ThemeMode.dark : ThemeMode.light);
            setState(() {});
          },
          title: const Text('Theme'),
          subtitle: Text(isDark ? 'Dark theme' : 'Light theme'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(ThemeData theme, String label, bool verified) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: Row(
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.error_outline,
            color: verified ? Colors.green : theme.colorScheme.error,
            size: 4.5.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text(
            verified ? 'Verified' : 'Pending',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: verified ? Colors.green : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(ThemeData theme, double rating) {
    return Row(
      children: [
        _buildRatingStars(theme, rating),
        SizedBox(width: 2.w),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars(ThemeData theme, double rating) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, size: 4.w, color: Colors.amber);
        }
        if (index == fullStars && hasHalf) {
          return Icon(Icons.star_half, size: 4.w, color: Colors.amber);
        }
        return Icon(
          Icons.star_border,
          size: 4.w,
          color: Colors.amber,
        );
      }),
    );
  }

  Widget _buildVehicleContent(ThemeData theme) {
    if (_isLoadingVehicles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Vehicles',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ..._vehicles.map((vehicle) => _buildVehicleCard(theme, vehicle)),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Vehicle'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.build),
                label: const Text('Maintenance'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleCard(ThemeData theme, Map<String, dynamic> vehicle) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${vehicle['year']} ${vehicle['make']} ${vehicle['model']}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    vehicle['status'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Plate: ${vehicle['plate']} • ${vehicle['color']} • ${vehicle['type']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.shield, size: 4.w, color: Colors.grey[600]),
                SizedBox(width: 2.w),
                Text(
                  'Insurance expires: ${vehicle['insurance_expiry']}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.build, size: 4.w, color: Colors.grey[600]),
                SizedBox(width: 2.w),
                Text(
                  'Last service: ${vehicle['last_service']}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportContent(ThemeData theme) {
    return Column(
      children: [
        _buildAccountOption(theme, Icons.help, 'Help Center', () {}),
        _buildAccountOption(theme, Icons.phone, 'Contact Support', () {}),
        _buildAccountOption(
          theme,
          Icons.emergency,
          'Emergency Assistance',
          () {},
        ),
        _buildAccountOption(theme, Icons.article, 'FAQs', () {}),
        _buildAccountOption(theme, Icons.feedback, 'Send Feedback', () {}),
        _buildAccountOption(theme, Icons.bug_report, 'Report Issue', () {}),
      ],
    );
  }

  Widget _buildEntertainmentContent(ThemeData theme) {
    final progress = _nowPlayingElapsedSeconds / _nowPlayingDurationSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Trip Music',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Card(
          color: const Color(0xFFE91E63).withAlpha(26),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      color: const Color(0xFFE91E63),
                      size: 8.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gospel Morning',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '6:00 AM - 9:00 AM',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isNowPlaying ? Icons.equalizer : Icons.pause_circle,
                      color: const Color(0xFFE91E63),
                      size: 6.w,
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFE91E63),
                  ),
                ),
                SizedBox(height: 0.8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(_nowPlayingElapsedSeconds),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      _formatTime(_nowPlayingDurationSeconds),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildAccountOption(
          theme,
          Icons.music_note,
          'Music Library',
          () => _openSpotify(),
        ),
        _buildAccountOption(
          theme,
          Icons.podcasts,
          'Podcasts',
          () => _openSpotify(),
        ),
        _buildAccountOption(
          theme,
          Icons.newspaper,
          'News',
          () => _openStandardMedia(),
        ),
        _buildAccountOption(
          theme,
          Icons.video_library,
          'Videos',
          () => _openYouTube(),
        ),
        _buildAccountOption(
          theme,
          Icons.settings,
          'Entertainment Settings',
          () {},
        ),
      ],
    );
  }

  Widget _buildCommunityContent(ThemeData theme) {
    return Column(
      children: [
        Card(
          color: const Color(0xFF673AB7).withAlpha(26),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Icon(Icons.groups, color: const Color(0xFF673AB7), size: 8.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Driver Community',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Connect with other drivers',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                  ),
                  child: const Text('Join'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildAccountOption(theme, Icons.forum, 'Driver Forums', () {}),
        _buildAccountOption(theme, Icons.location_city, 'Local Groups', () {}),
        _buildAccountOption(theme, Icons.people, 'User Profiles', () {}),
        _buildAccountOption(theme, Icons.event, 'Events', () {}),
        _buildAccountOption(theme, Icons.chat, 'Messages', () {}),
      ],
    );
  }

  Widget _buildLogoutContent(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Are you sure you want to log out?',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _toggleCategory('Log Out'),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountOption(
    ThemeData theme,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 6.w),
            SizedBox(width: 3.w),
            Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
