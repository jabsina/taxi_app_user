import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app_user/widget/call_confirmation_sheet.dart';
import 'package:taxi_app_user/services/api_service.dart';
import 'package:taxi_app_user/services/notifications_services.dart';
import 'package:taxi_app_user/models/ride_model.dart';
import 'package:taxi_app_user/models/user_model.dart';
import 'package:taxi_app_user/screen/loginscreen.dart';
import 'package:taxi_app_user/screen/main_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isWaitingForApproval = false;
  bool isRequestingRide = false;
  String? currentRideId;

  String pickupLocationText = 'Enter pickup location';

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // ---------------- LOCATION RESOLVE (NO SUGGESTIONS) ----------------
  Future<Map<String, dynamic>?> getLocationFromText(String query) async {
    if (query.trim().isEmpty) return null;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
          '?q=$query&format=json&limit=1&countrycodes=in',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'taxi-app'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) return data[0];
    }
    return null;
  }

  // ---------------- CALL ADMIN ----------------
  Future<void> _callAdminNumber() async {
    const adminNumber = '+919876543210';
    final uri = Uri(scheme: 'tel', path: adminNumber);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot launch dialer')),
      );
    }
  }

  // ---------------- REQUEST BUTTON ----------------
  void _onRequestRide() {
    if (isRequestingRide) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CallConfirmationSheet(
          onConfirm: () async {
            await _callAdminNumber();
            await _requestRide();
          },
        );
      },
    );
  }

  // ---------------- RIDE REQUEST ----------------
  Future<void> _requestRide() async {
    FocusScope.of(context).unfocus();

    if (pickupController.text.trim().isEmpty ||
        destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter pickup & destination')),
      );
      return;
    }

    setState(() => isRequestingRide = true);

    try {
      final response = await ApiService.requestRide(
        pickupController.text.trim(),
        destinationController.text.trim(),
      );

      setState(() {
        currentRideId = response.ride.id;
        isWaitingForApproval = true;
      });

      NotificationService.show(
        title: 'Ride Requested',
        body: response.message,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen(initialIndex: 1),
          ),
        );
      }
    } catch (e) {
      // 🔥 SESSION EXPIRED → ApiService already redirected to Login
      if (e is SessionExpiredException) {
        return;
      }

      // Normal error (network, validation, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride request failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    finally {
      setState(() => isRequestingRide = false);
    }
  }

  void _handleAuthError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GetStartedPage()),
            );
          },
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2A3A),
        title: const Text(
          'TraveLink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _pickupBox(),
            const SizedBox(height: 20),
            _destinationBox(),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _onRequestRide,
              child: _requestRideButton(),
            ),

          ],
        ),
      ),
    );
  }

  // ---------------- INPUT BOXES ----------------
  Widget _pickupBox() {
    return _inputBox(
      icon: Icons.my_location,
      iconColor: Colors.green,
      controller: pickupController,
      hint: pickupLocationText,
    );
  }

  Widget _destinationBox() {
    return _inputBox(
      icon: Icons.location_on,
      iconColor: Colors.redAccent,
      controller: destinationController,
      hint: 'Enter destination',
    );
  }

  Widget _inputBox({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BUTTON ----------------
  Widget _requestRideButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A3A), Color(0xFF1A3B5A)],
        ),
      ),
      child: Center(
        child: isRequestingRide
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Request Ride',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
