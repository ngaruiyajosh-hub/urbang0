import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/theme_service.dart';
import '../available_rides_screen/widgets/filter_chip_widget.dart';
import '../available_rides_screen/widgets/vehicle_card_widget.dart';
import '../my_wallet_screen/widgets/balance_card_widget.dart';
import '../my_wallet_screen/widgets/quick_action_button.dart';
import '../my_wallet_screen/widgets/transaction_item_widget.dart';
import '../payment_screen/widgets/booking_info_widget.dart';
import '../payment_screen/widgets/payment_method_card.dart';

/// More Screen - Displays all app categories with collapsible sections
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _supabase = SupabaseService.client;
  String? _expandedCategory;
  bool _didAutoExpandCategory = false;
  Timer? _nowPlayingTimer;
  int _nowPlayingElapsedSeconds = 0;
  final int _nowPlayingDurationSeconds = 225;
  final bool _isNowPlaying = true;

  // Payment state
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _showFareBreakdown = false;

  // Wallet state
  bool _isRefreshing = false;
  String _selectedTransactionFilter = 'All';
  final List<String> _transactionFilters = [
    'All',
    'Rides',
    'Top-ups',
    'Refunds',
  ];

  // Rides state
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoadingVehicles = false;
  String _selectedRideFilter = 'All';
  final List<String> _rideFilters = ['All', 'Economy', 'Premium', 'Shared'];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card_1',
      'type': 'Credit Card',
      'name': 'Visa •••• 4242',
      'icon': Icons.credit_card,
      'isDefault': true,
    },
    {
      'id': 'card_2',
      'type': 'Debit Card',
      'name': 'Mastercard •••• 8888',
      'icon': Icons.credit_card,
      'isDefault': false,
    },
    {
      'id': 'wallet',
      'type': 'Digital Wallet',
      'name': 'My Wallet (Ksh 125.50)',
      'icon': Icons.account_balance_wallet,
      'isDefault': false,
    },
    {
      'id': 'cash',
      'type': 'Cash',
      'name': 'Pay with Cash',
      'icon': Icons.money,
      'isDefault': false,
    },
  ];

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'txn_1',
      'type': 'ride',
      'description': 'Ride to Downtown',
      'amount': -24.50,
      'date': '2026-02-04 14:30',
      'status': 'completed',
      'icon': Icons.directions_car,
      'color': Color(0xFFFF9800),
    },
    {
      'id': 'txn_2',
      'type': 'topup',
      'description': 'Wallet Top-up',
      'amount': 100.00,
      'date': '2026-02-03 10:15',
      'status': 'completed',
      'icon': Icons.add_circle,
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'txn_3',
      'type': 'ride',
      'description': 'Ride to Airport',
      'amount': -45.75,
      'date': '2026-02-02 08:45',
      'status': 'completed',
      'icon': Icons.directions_car,
      'color': Color(0xFFFF9800),
    },
    {
      'id': 'txn_4',
      'type': 'refund',
      'description': 'Cancelled Ride Refund',
      'amount': 18.00,
      'date': '2026-02-01 16:20',
      'status': 'completed',
      'icon': Icons.refresh,
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'txn_5',
      'type': 'ride',
      'description': 'Ride to Shopping Mall',
      'amount': -32.25,
      'date': '2026-01-31 12:00',
      'status': 'completed',
      'icon': Icons.directions_car,
      'color': Color(0xFFFF9800),
    },
    {
      'id': 'txn_6',
      'type': 'topup',
      'description': 'Wallet Top-up',
      'amount': 50.00,
      'date': '2026-01-30 09:30',
      'status': 'completed',
      'icon': Icons.add_circle,
      'color': Color(0xFF4CAF50),
    },
  ];
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = false;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = _paymentMethods.firstWhere(
      (method) => method['isDefault'] == true,
      orElse: () => _paymentMethods.first,
    )['id'];
    _startNowPlayingTimer();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nowPlayingTimer?.cancel();
    super.dispose();
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

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategory == category) {
        _expandedCategory = null;
      } else {
        _expandedCategory = category;
        // Load data when expanding specific categories
        if (category == 'Available Rides' && _vehicles.isEmpty) {
          _loadVehicles();
        }
      }
    });
  }

  Future<void> _loadVehicles() async {
    try {
      setState(() => _isLoadingVehicles = true);
      final response = await _supabase
          .from('Vehicle')
          .select('*, User!Vehicle_driver_id_fkey(name)')
          .eq('status', 'Available');

      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(response);
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
        case 'Rides':
          return txn['type'] == 'ride';
        case 'Top-ups':
          return txn['type'] == 'topup';
        case 'Refunds':
          return txn['type'] == 'refund';
        default:
          return true;
      }
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredVehicles {
    if (_selectedRideFilter == 'All') return _vehicles;
    return _vehicles
        .where((v) => v['vehicle_type'] == _selectedRideFilter)
        .toList();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isProcessing = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.check_circle,
            color: const Color(0xFF4CAF50),
            size: 15.w,
          ),
          title: const Text('Payment Successful'),
          content: const Text(
            'Your booking has been confirmed. You will receive a confirmation shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _refreshBalance() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Balance updated')));
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Transaction Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              _buildDetailRow(theme, 'Description', transaction['description']),
              _buildDetailRow(
                theme,
                'Amount',
                'Ksh ${transaction['amount'].abs().toStringAsFixed(2)}',
              ),
              _buildDetailRow(theme, 'Date', transaction['date']),
              _buildDetailRow(theme, 'Status', transaction['status']),
              _buildDetailRow(theme, 'Transaction ID', transaction['id']),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt downloaded')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download),
                    SizedBox(width: 2.w),
                    const Text('Download Receipt'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AuthService authService = AuthService();

    final String? selectedCategory =
        ModalRoute.of(context)?.settings.arguments as String?;

    if (selectedCategory != null && !_didAutoExpandCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _expandedCategory = selectedCategory;
          _didAutoExpandCategory = true;
          if (selectedCategory == 'Available Rides' && _vehicles.isEmpty) {
            _loadVehicles();
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('More'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Text(
                'Categories',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            _buildCollapsibleCategory(
              theme,
              'Payment',
              Icons.payment,
              const Color(0xFF2196F3),
              _buildPaymentContent(theme),
            ),
            _buildCollapsibleCategory(
              theme,
              'My Wallet',
              Icons.account_balance_wallet,
              const Color(0xFF4CAF50),
              _buildWalletContent(theme),
            ),
            _buildCollapsibleCategory(
              theme,
              'Available Rides',
              Icons.directions_car,
              const Color(0xFFFF9800),
              _buildRidesContent(theme),
            ),
            _buildCollapsibleCategory(
              theme,
              'My account',
              Icons.person,
              const Color(0xFF9C27B0),
              _buildAccountContent(theme),
            ),
            _buildCollapsibleCategory(
              theme,
              'Support',
              Icons.support_agent,
              const Color(0xFFF44336),
              _buildSupportContent(theme),
            ),
            _buildCollapsibleCategory(
              theme,
              'Entertainment',
              Icons.movie,
              const Color(0xFFE91E63),
              _buildEntertainmentContent(theme),
            ),
            _buildCollapsibleCategory(
              theme,
              'Community',
              Icons.people,
              const Color(0xFF00BCD4),
              _buildCommunityContent(theme),
            ),

            SizedBox(height: 3.h),
            Divider(color: theme.dividerColor),
            SizedBox(height: 1.h),

            _buildLogoutItem(theme, authService),
          ],
        ),
      ),
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

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: isExpanded ? color.withValues(alpha: 0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isExpanded ? color : theme.dividerColor.withValues(alpha: 0.2),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.h,
            ),
            leading: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
              size: 6.w,
              color: isExpanded ? color : theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () => _toggleCategory(title),
          ),
          if (isExpanded) Padding(padding: EdgeInsets.all(4.w), child: content),
        ],
      ),
    );
  }

  Widget _buildPaymentContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingInfoWidget(),
        SizedBox(height: 2.h),

        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fare Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFareBreakdown = !_showFareBreakdown;
                      });
                    },
                    icon: Icon(
                      _showFareBreakdown
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 5.w,
                    ),
                    label: Text(_showFareBreakdown ? 'Hide' : 'Details'),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: theme.textTheme.bodyLarge),
                  Text(
                    r'Ksh 24.50',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (_showFareBreakdown) ...[
                SizedBox(height: 2.h),
                _buildFareBreakdown(theme),
              ],
            ],
          ),
        ),
        SizedBox(height: 3.h),

        Text(
          'Select Payment Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.5.h),

        ..._paymentMethods.map(
          (method) => PaymentMethodCard(
            id: method['id'],
            type: method['type'],
            name: method['name'],
            icon: method['icon'],
            isSelected: _selectedPaymentMethod == method['id'],
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method['id'];
              });
            },
          ),
        ),

        SizedBox(height: 2.h),

        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add payment method feature coming soon'),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Payment Method'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
          ),
        ),

        SizedBox(height: 2.h),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Confirm Payment'),
          ),
        ),
      ],
    );
  }

  Widget _buildFareBreakdown(ThemeData theme) {
    return Column(
      children: [
        Divider(color: theme.dividerColor),
        SizedBox(height: 1.h),
        _buildFareRow(theme, 'Base Fare', r'Ksh 5.00'),
        _buildFareRow(theme, 'Distance (8.5 km)', r'Ksh 12.75'),
        _buildFareRow(theme, 'Time (15 min)', r'Ksh 4.50'),
        _buildFareRow(theme, 'Service Fee', r'Ksh 2.25'),
        _buildFareRow(theme, 'Promo Discount', r'-Ksh 2.00', isDiscount: true),
        _buildFareRow(theme, 'Tax (8%)', r'Ksh 2.00'),
        SizedBox(height: 1.h),
        Divider(color: theme.dividerColor),
        SizedBox(height: 1.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              r'Ksh 24.50',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFareRow(
    ThemeData theme,
    String label,
    String amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDiscount
                  ? const Color(0xFF4CAF50)
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BalanceCardWidget(balance: 125.50, isRefreshing: _isRefreshing),
        SizedBox(height: 3.h),

        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.add,
                label: 'Add Money',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add money feature coming soon'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: QuickActionButton(
                icon: Icons.send,
                label: 'Send Money',
                color: const Color(0xFF2196F3),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Send money feature coming soon'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: QuickActionButton(
                icon: Icons.refresh,
                label: 'Refresh',
                color: const Color(0xFFFF9800),
                onTap: _refreshBalance,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View all transactions')),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 1.h),

        SizedBox(
          height: 6.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _transactionFilters.length,
            itemBuilder: (context, index) {
              return FilterChipWidget(
                label: _transactionFilters[index],
                isSelected:
                    _selectedTransactionFilter == _transactionFilters[index],
                onTap: () {
                  setState(
                    () =>
                        _selectedTransactionFilter = _transactionFilters[index],
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 2.h),

        ..._filteredTransactions
            .take(5)
            .map(
              (transaction) => TransactionItemWidget(
                transaction: transaction,
                onTap: () => _showTransactionDetails(transaction),
              ),
            ),
      ],
    );
  }

  Widget _buildRidesContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Vehicles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadVehicles,
            ),
          ],
        ),
        SizedBox(height: 1.h),

        SizedBox(
          height: 6.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _rideFilters.length,
            itemBuilder: (context, index) {
              return FilterChipWidget(
                label: _rideFilters[index],
                isSelected: _selectedRideFilter == _rideFilters[index],
                onTap: () {
                  setState(() => _selectedRideFilter = _rideFilters[index]);
                },
              );
            },
          ),
        ),
        SizedBox(height: 2.h),

        _isLoadingVehicles
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(4.h),
                  child: CircularProgressIndicator(),
                ),
              )
            : _filteredVehicles.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(4.h),
                  child: Column(
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
                      SizedBox(height: 1.h),
                      Text(
                        'Please try again later',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: _filteredVehicles.map((vehicle) {
                  return VehicleCardWidget(
                    vehicle: vehicle,
                    onBook: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Booking'),
                          content: Text(
                            'Book ride with ${vehicle['User']?['name'] ?? 'driver'}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ride booked successfully!'),
                                  ),
                                );
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
      ],
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
          child: _buildProfileInfo(theme),
        ),
        SizedBox(height: 1.h),
        _buildAccountSection(
          theme,
          title: 'Ride History',
          icon: Icons.history,
          child: _buildRideHistory(theme),
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

  Widget _buildProfileInfo(ThemeData theme) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = _userProfile?['name'] ?? 'User';
    final email = _userProfile?['email'] ?? '';
    final phone = _userProfile?['phone number'] ?? _userProfile?['phone'] ?? '';
    final address = _userProfile?['home_address'] ?? 'Nairobi, Kenya';

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

  Widget _buildRideHistory(ThemeData theme) {
    final rides = [
      'Nairobi CBD > Rongai 5 hours ago',
      'Westlands > CBD 1 day ago',
      'Kilimani > Upper Hill 2 days ago',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rides
          .map(
            (ride) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.6.h),
              child: Text(ride, style: theme.textTheme.bodySmall),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCommonRoutes(ThemeData theme) {
    final routes = [
      'Route 100 Kiambu',
      'Route 125 Rongai',
      'Route 111 Ngong',
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

  Widget _buildSupportContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'We\'re here to help',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        _buildInfoCard(
          theme,
          'Help Center',
          'Browse FAQs and guides',
          Icons.help_outline,
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'Contact Support',
          'Chat with our support team',
          Icons.chat_bubble_outline,
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'Report Issue',
          'Report a problem with your ride',
          Icons.report_problem_outlined,
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'Emergency',
          '24/7 emergency assistance',
          Icons.emergency,
        ),
      ],
    );
  }

  Widget _buildEntertainmentContent(ThemeData theme) {
    final progress = _nowPlayingElapsedSeconds / _nowPlayingDurationSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE91E63),
                const Color(0xFFE91E63).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white, size: 8.w),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Now Playing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        Text(
                          'Gospel Morning (6-9 AM)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isNowPlaying ? Icons.equalizer : Icons.pause_circle,
                    color: Colors.white,
                    size: 6.w,
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
              SizedBox(height: 0.8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(_nowPlayingElapsedSeconds),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    _formatTime(_nowPlayingDurationSeconds),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        _buildInfoCard(
          theme,
          'Podcasts',
          'Listen to trending podcasts',
          Icons.podcasts,
          onTap: () => _openSpotify(),
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'News',
          'Stay updated with latest news',
          Icons.newspaper,
          onTap: () => _openStandardMedia(),
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'Music',
          'Explore music playlists',
          Icons.library_music,
          onTap: () => _openSpotify(),
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'Videos',
          'Watch entertaining videos',
          Icons.video_library,
          onTap: () => _openYouTube(),
        ),
      ],
    );
  }

  Widget _buildCommunityContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Connect with other riders',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        _buildInfoCard(theme, 'Groups', 'Join community groups', Icons.groups),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'User Profiles',
          'View and connect with riders',
          Icons.account_circle,
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'Events',
          'Discover community events',
          Icons.event,
        ),
        SizedBox(height: 1.h),
        _buildInfoCard(
          theme,
          'Forums',
          'Participate in discussions',
          Icons.forum,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 6.w, color: theme.colorScheme.primary),
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
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(ThemeData theme, AuthService authService) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(Icons.logout, color: const Color(0xFFF44336), size: 6.w),
      ),
      title: Text(
        'Logout',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF44336),
        ),
      ),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          await authService.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (route) => false,
            );
          }
        }
      },
    );
  }
}
