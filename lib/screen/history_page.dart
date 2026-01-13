import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Map<String, dynamic>> rideHistory = [
    {
      'user': 'Saniya',
      'driver': 'Alex',
      'driverPhone': '8888888888',
      'userPhone': '9999999999',
      'pickup': 'MG Road, Kochi',
      'from': 'Kaloor, Kochi',
      'to': 'Infopark, Kakkanad',
      'status': 'Completed',
      'requestedAt': '2026-01-07 13:39',
      'assignedAt': '2026-01-07 13:41',
      'startedAt': '2026-01-07 13:44',
      'endedAt': '2026-01-07 13:54',
      'duration': '10 mins',
      'baseFare': 200,
      'extraFare': 50,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            /// Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF0F2A3A)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ride History',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2A3A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// List
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
    );
  }

  /// ================= HISTORY CARD =================
  Widget _historyCard(Map<String, dynamic> ride) {
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
                    '${ride['from']} → ${ride['to']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2A3A),
                    ),
                  ),
                ),
                _statusBadge(ride['status']),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ride['requestedAt'],
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
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
  void _showRideDetails(Map<String, dynamic> ride) {
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

                Text(
                  ride['driver'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                _detailRow(Icons.phone, 'Driver Phone', ride['driverPhone']),
                _detailRow(Icons.person, 'User Phone', ride['userPhone']),
                _detailRow(Icons.location_on, 'Pickup', ride['pickup']),

                const Divider(height: 32),

                _detailRow(Icons.info, 'Status', ride['status']),
                _detailRow(Icons.access_time, 'Requested At', ride['requestedAt']),
                _detailRow(Icons.check_circle, 'Assigned At', ride['assignedAt']),
                _detailRow(Icons.play_arrow, 'Started At', ride['startedAt']),
                _detailRow(Icons.stop, 'Ended At', ride['endedAt']),
                _detailRow(Icons.timer, 'Duration', ride['duration']),

                const Divider(height: 32),

                _detailRow(Icons.attach_money, 'Base Fare', '₹ ${ride['baseFare']}'),
                _detailRow(Icons.add, 'Additional Fare', '₹ ${ride['extraFare']}'),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Fare',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₹ ${ride['baseFare'] + ride['extraFare']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

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
