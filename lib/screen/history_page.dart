import 'package:flutter/material.dart';
import 'package:taxi_app_user/utils/network_util.dart';
import 'package:taxi_app_user/widget/no_internet_widget.dart';
import '../services/api_service.dart';
import '../models/ride_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Ride> rideHistory = [];

  String? errorMessage;
  bool hasNetwork = true;
  bool checkingNetwork = true;
  bool isLoading = true;

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

    await _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getRideHistory();
      setState(() {
        rideHistory = response.rides;
        isLoading = false;
      });
    } catch (e) {
      if (e is SessionExpiredException) {
        return;
      }

      if (e.toString().contains('SocketException') ||
          e.toString().contains('No internet')) {
        setState(() {
          hasNetwork = false;
          isLoading = false;
        });
      }}}

  Future<void> _refreshHistory() async {
    await _loadRideHistory();
  }

  Future<void> _cancelRide(String rideId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              try {
                await ApiService.cancelRide(rideId);
                // Check if widget is still mounted before showing snackbar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ride cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Automatic refresh after successful cancellation
                  _refreshHistory();
                }
              } catch (e) {
                // 🔥 Ignore session expiry here too
                if (e is SessionExpiredException) {
                  return;
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel ride: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ While checking internet
    if (checkingNetwork) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ No internet → show full page
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
          'Ride History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshHistory,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),

      backgroundColor: const Color(0xFFF6F2F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHistory,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRideHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (rideHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No ride history available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rideHistory.length,
                    itemBuilder: (context, index) {
                      return _historyCard(rideHistory[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= HISTORY CARD =================
  Widget _historyCard(Ride ride) {
    return GestureDetector(
      onTap: () => _showRideDetails(ride),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Text(
                    '${ride.pickupAddress} → ${ride.dropAddress ?? 'Destination'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2A3A),
                    ),
                  ),
                ),
                _statusBadge(ride.status),
                if (ride.status == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                      onPressed: () => _cancelRide(ride.id),
                      tooltip: 'Cancel Ride',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _formatDateTime(ride.requestedAt),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal(); // ✅ VERY IMPORTANT

    return '${local.day.toString().padLeft(2, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// ================= STATUS BADGE =================
  Widget _statusBadge(String status) {
    Color bg;
    Color text;

    if (status == 'Completed') {
      bg = Colors.green.shade100;
      text = Colors.green.shade800;
    } else if (status == 'Cancelled') {
      bg = Colors.red.shade100;
      text = Colors.red.shade800;
    } else {
      bg = Colors.orange.shade100;
      text = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  /// ================= BOTTOM SHEET =================
  void _showRideDetails(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Ride Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                _detailRow(Icons.location_on, 'Pickup', ride.pickupAddress),
                if (ride.dropAddress != null)
                  _detailRow(Icons.flag, 'Destination', ride.dropAddress!),

                const Divider(height: 32),

                _detailRow(Icons.info, 'Status', ride.status),
                _detailRow(Icons.access_time, 'Requested At', _formatDateTime(ride.requestedAt)),
                if (ride.assignedAt != null)
                  _detailRow(Icons.check_circle, 'Assigned At', _formatDateTime(ride.assignedAt!)),
                if (ride.startedAt != null)
                  _detailRow(Icons.play_arrow, 'Started At', _formatDateTime(ride.startedAt!)),
                if (ride.endedAt != null)
                  _detailRow(Icons.stop, 'Ended At', _formatDateTime(ride.endedAt!)),
                if (ride.durationMinutes != null)
                  _detailRow(Icons.timer, 'Duration', '${ride.durationMinutes} minutes'),

                const Divider(height: 32),

                _detailRow(Icons.attach_money, 'Total Fare', '₹${ride.totalFare}'),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= DETAIL ROW =================
  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}