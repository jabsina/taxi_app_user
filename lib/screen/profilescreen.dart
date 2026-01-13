import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color primaryColor = Color(0xFF0E2A38);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔹 Proper AppBar (professional apps always have this)
      appBar:AppBar(
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
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          /// PROFILE IMAGE
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundImage: const AssetImage(
                'assets/images/Profile.png',
              ),
              backgroundColor: Colors.grey.shade200,
            ),
          ),

          const SizedBox(height: 16),

          /// NAME
          const Center(
            child: Text(
              'Saniya Benny',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          /// PHONE
          const Center(
            child: Text(
              '+91 98765 43210',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 30),

          /// MAIN INFO CARD (THEME COLOR)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                _ProfileTile(
                  icon: Icons.person_outline,
                  title: 'Username',
                  value: 'saniya_benny',
                ),
                Divider(height: 28, color: Colors.white24),
                _ProfileTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: '+91 98765 43210',
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// OPTIONAL ACTION
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                // logout later
              },
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
        ],
      ),
    );
  }
}

/// TILE USED INSIDE THE DARK CARD
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
