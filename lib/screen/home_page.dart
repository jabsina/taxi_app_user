import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app_user/widget/call_confirmation_sheet.dart';
import 'package:taxi_app_user/services/api_service.dart';
import 'package:taxi_app_user/services/notifications_services.dart';
import 'package:taxi_app_user/screen/loginscreen.dart';
import 'package:taxi_app_user/screen/main_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/network_util.dart';
import '../widget/no_internet_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isWaitingForApproval = false;
  bool isRequestingRide = false;
  String? currentRideId;
  bool hasNetwork = true;
  bool checkingNetwork = true;

  String pickupLocationText = 'Enter pickup location';

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkNetwork();
  }

  // 🌐 CHECK NETWORK STATUS
  Future<void> checkNetwork() async {
    final connected = await hasInternet();
    setState(() {
      hasNetwork = connected;
      checkingNetwork = false;
    });
  }

  // ---------------- CALL ADMIN ----------------
  Future<void> _callAdminNumber() async {
    const adminNumber = '+919847081797';
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

    final connected = await hasInternet();
    if (!connected) {
      setState(() {
        hasNetwork = false;
        checkingNetwork = false;
        isRequestingRide = false;
      });
      return;
    }

    if (pickupController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter pickup & required duration')),
      );
      return;
    }

    setState(() => isRequestingRide = true);

    try {
      final response = await ApiService.requestRide(
        pickupController.text.trim(),
        durationController.text.trim(),
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
      if (e is SessionExpiredException) return;
    } finally {
      setState(() => isRequestingRide = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (checkingNetwork) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasNetwork) {
      return NoInternetWidget(
        onRetry: () async {
          setState(() => checkingNetwork = true);
          await checkNetwork();
        },
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2A3A),
        title: const Text(
          'Driver Link',
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _pickupBox(),
            const SizedBox(height: 20),
            _durationBox(),
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

  Widget _durationBox() {
    return _inputBox(
      icon: Icons.timer,
      iconColor: Colors.orange,
      controller: durationController,
      hint: 'Required Duration ',
      keyboardType: TextInputType.number,
    );
  }

  Widget _inputBox({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
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
              keyboardType: keyboardType,
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
