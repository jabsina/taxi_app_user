import 'package:flutter/material.dart';
import 'package:taxi_app_user/screen/loginscreen.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';
import 'package:taxi_app_user/utils/network_util.dart';
import 'package:taxi_app_user/widget/no_internet_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? userProfile;
  bool isLoading = true;
  String? errorMessage;
  bool hasNetwork = true;
  bool checkingNetwork = true;

  @override
  void initState() {
    super.initState();
    _init();
  }
  Future<void> _init() async {
    final connected = await hasInternet();

    if (!connected) {
      setState(() {
        hasNetwork = false;
        checkingNetwork = false;
        isLoading = false;
      });
      return;
    }

    setState(() {
      hasNetwork = true;
      checkingNetwork = false;
    });

    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final profile = await ApiService.getUserProfile();
      setState(() {
        userProfile = profile;
        isLoading = false;
      });
    }catch (e) {
      if (e is SessionExpiredException) {
        return;
      }

      if (e.toString().contains('SocketException') ||
          e.toString().contains('No internet')) {
        setState(() {
          hasNetwork = false;
          isLoading = false;
        });
        return;
      }

      setState(() {
        errorMessage = 'Failed to load profile';
        isLoading = false;
      });
    }}



    /// 🔐 REAL LOGOUT (UNCHANGED)
  Future<void> _logout() async {
    await SecureStorageService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedPage()),
          (route) => false,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B2A3A),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _refreshProfile() async {
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ Checking network
    if (checkingNetwork) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ No internet → full page
    if (!hasNetwork) {
      return NoInternetWidget(
        onRetry: () async {
          setState(() {
            checkingNetwork = true;
          });
          await _init();
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F2A3A),
        centerTitle: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshProfile,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F2F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: Column(
            children: [
              const SizedBox(height: 20),

              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUserProfile,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (userProfile != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _profileCard(),
                          const SizedBox(height: 20),
                          _statsCard(),
                          const SizedBox(height: 30),
                          _logoutButton(context),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A3A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF0F2A3A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile!.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2A3A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProfile!.phoneNumber,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(
            Icons.email,
            'User ID',
            userProfile!.id.substring(0, 8) + '...',
          ),
          _detailRow(
            Icons.phone,
            'Phone Number',
            userProfile!.phoneNumber,
          ),
          _detailRow(
            Icons.access_time,
            'Member Since',
            _formatDate(userProfile!.createdAt),
          ),
          if (userProfile!.lastLogin != null)
            _detailRow(
              Icons.login,
              'Last Login',
              _formatDate(userProfile!.lastLogin!),
            ),
          _detailRow(
            Icons.verified_user,
            'Account Status',
            userProfile!.isActive ? 'Active' : 'Inactive',
            valueColor: userProfile!.isActive ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2A3A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  'Total Rides',
                  userProfile!.stats.totalRides.toString(),
                  Icons.directions_car,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  'Completed',
                  userProfile!.stats.completedRides.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  'Total Spent',
                  '₹${userProfile!.stats.totalSpent}',
                  Icons.attach_money,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  'Avg Fare',
                  '₹${userProfile!.stats.avgFare.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _logoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B2A3A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _showLogoutDialog, // ✅ IMPORTANT
          child: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }



  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
  }
}