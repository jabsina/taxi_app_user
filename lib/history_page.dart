import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> rideHistory = [
    {
      'from': 'Kaloor, Kochi',
      'to': 'Infopark, Kakkanad',
      'date': '06 Jan 2026',
      'time': '8:45 PM',
      'status': 'Completed',
    },
    {
      'from': 'MG Road',
      'to': 'Vytilla Hub',
      'date': '02 Jan 2026',
      'time': '6:10 PM',
      'status': 'Cancelled',
    },
    {
      'from': 'Edappally',
      'to': 'Lulu Mall',
      'date': '28 Dec 2025',
      'time': '4:30 PM',
      'status': 'Pending',
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
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0F2A3A),
                    ),
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

            Expanded(
              child: rideHistory.isEmpty
                  ? _emptyState()
                  : ListView.builder(
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

  Widget _historyCard(Map<String, dynamic> ride) {
    return Container(
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
            '${ride['date']} • ${ride['time']}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;

    if (status == 'Completed') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else if (status == 'Cancelled') {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
    } else {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.black26,
          ),
          SizedBox(height: 12),
          Text(
            'No rides yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Book your first ride to see history here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
