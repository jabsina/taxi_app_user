// ... all your imports remain the same
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app_user/widget/call_confirmation_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isWaitingForApproval = false;

  String pickupLocationText = 'Fetching pickup location...';

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  List<dynamic> pickupSuggestions = [];
  List<dynamic> destinationSuggestions = [];

  bool pickupSelected = false;
  bool destinationSelected = false;

  @override
  void initState() {
    super.initState();
    _getPickupLocation();
  }

  // ---------------- LOCATION ----------------
  Future<void> _getPickupLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        pickupLocationText = 'Location permission denied';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await _getAddressFromLatLng(position.latitude, position.longitude);
  }

  Future<void> _getAddressFromLatLng(double lat, double lon) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');

    final response = await http.get(url, headers: {'User-Agent': 'taxi-app'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        pickupLocationText = data['display_name'] ?? 'Unknown location';
        pickupController.text = pickupLocationText;
        pickupSelected = true;
      });
    }
  }

  // ---------------- SEARCH ----------------
  Future<void> searchPickupPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => pickupSuggestions = []);
      return;
    }

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=in');

    final response = await http.get(url, headers: {'User-Agent': 'taxi-app'});

    if (response.statusCode == 200) {
      setState(() {
        pickupSuggestions = json.decode(response.body);
        pickupSelected = false;
      });
    }
  }

  Future<void> searchDestinationPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => destinationSuggestions = []);
      return;
    }

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=in');

    final response = await http.get(url, headers: {'User-Agent': 'taxi-app'});

    if (response.statusCode == 200) {
      setState(() {
        destinationSuggestions = json.decode(response.body);
        destinationSelected = false;
      });
    }
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

  void _onRequestRide() {
    FocusScope.of(context).unfocus();

    if (!pickupSelected || !destinationSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select pickup & destination')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CallConfirmationSheet(onConfirm: _callAdminNumber),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0F2A3A),
          centerTitle: true,
          title: const Text(
            'Taxi App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
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
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F2F8), Color(0xFFEFEAF3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  _pickupBox(),
                  if (pickupSuggestions.isNotEmpty) _pickupSuggestionList(),
                  const SizedBox(height: 20),
                  _destinationBox(),
                  if (destinationSuggestions.isNotEmpty)
                    _destinationSuggestionList(),
                  const SizedBox(height: 20),
                  // Request Ride button now directly under destination box
                  GestureDetector(
                    onTap: _onRequestRide,
                    child: _requestRideButton(),
                  ),
                ],
              ),
            ),
          ),
          if (isWaitingForApproval)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(child: _waitingApprovalCard()),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- WIDGETS ----------------
  Widget _pickupBox() {
    return _inputBox(
      icon: Icons.my_location,
      iconColor: Colors.green,
      controller: pickupController,
      hint: pickupLocationText,
      onChanged: searchPickupPlaces,
    );
  }

  Widget _destinationBox() {
    return _inputBox(
      icon: Icons.location_on,
      iconColor: Colors.redAccent,
      controller: destinationController,
      hint: 'Enter destination',
      onChanged: searchDestinationPlaces,
    );
  }

  Widget _inputBox({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
              onChanged: onChanged,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.black54),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickupSuggestionList() {
    return _suggestionList(pickupSuggestions, (place) {
      setState(() {
        pickupController.text = place['display_name'];
        pickupSuggestions = [];
        pickupSelected = true;
      });
    });
  }

  Widget _destinationSuggestionList() {
    return _suggestionList(destinationSuggestions, (place) {
      setState(() {
        destinationController.text = place['display_name'];
        destinationSuggestions = [];
        destinationSelected = true;
      });
    });
  }

  Widget _suggestionList(List<dynamic> list, Function(dynamic) onTap) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = list[index];
          return ListTile(
            title: Text(place['display_name'], maxLines: 2),
            onTap: () => onTap(place),
          );
        },
      ),
    );
  }

  Widget _requestRideButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A3A), Color(0xFF1A3B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Request Ride',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _waitingApprovalCard() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0F2A3A),
          ),
          const SizedBox(height: 16),
          const Text(
            'Waiting for approval',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => isWaitingForApproval = false),
            child: const Text(
              'Cancel Request',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
