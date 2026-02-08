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
  List<dynamic> pickupSuggestions = [];
  bool showPickupSuggestions = false;
  bool isWaitingForApproval = false;
  bool isRequestingRide = false;
  bool pickupSelected = false;
  String? currentRideId;

  String pickupLocationText = 'Enter pickup location';

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  
  int selectedHours = 2; // Default to 2 hours

  bool hasNetwork = true;
  bool checkingNetwork = true;

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
  Future<void> fetchPickupSuggestions(String input) async {
    print('ON_CHANGED CALLED WITH: $input');
    if (input.isEmpty) {
      setState(() {
        pickupSuggestions.clear();
        showPickupSuggestions = false;
      });
      return;
    }

    final encodedInput = Uri.encodeComponent(input);


    final url = Uri.parse(
      'https://photon.komoot.io/api/?q=$encodedInput&limit=10&lang=en',
    );




    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DriverLinkApp/1.0 (contact@driverlink.com)',
        },
      );

      if (response.statusCode == 200) {
        final List features = json.decode(response.body)['features'];
        print('PHOTON RESULTS COUNT: ${features.length}');
        setState(() {
          pickupSuggestions = features;
          showPickupSuggestions = pickupSuggestions.isNotEmpty;
        });
      }

    } catch (e) {
      debugPrint('OSM error: $e');
    }
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
  // ---------------- REQUEST BUTTON ----------------
  void _onRequestRide() {
    // ❗ GUARD: user must select from suggestions
    if (!pickupSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup location from suggestions'),
        ),
      );
      return;
    }

    // ❗ GUARD: avoid double request
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

    if (pickupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter pickup address')),
      );
      return;
    }

    setState(() => isRequestingRide = true);

    try {
      final response = await ApiService.requestRide(
        pickupController.text.trim(),
        requiredTimeHours: selectedHours,
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pickupBox(),
            const SizedBox(height: 20),
            _timeSelector(),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _onRequestRide,
              child: _requestRideButton(),
            ),
          ],
        ),
      ),
        )
    );
  }

  // ---------------- INPUT BOXES ----------------
  Widget _pickupBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputBox(
          icon: Icons.my_location,
          iconColor: Colors.green,
          controller: pickupController,
          hint: pickupLocationText,
          onChanged: (value) {
            setState(() {
              pickupSelected = false;
            });
            fetchPickupSuggestions(value);
          },
        ),

        // 🔽 Suggestions List
        if (showPickupSuggestions) _pickupSuggestionsList(),
      ],
    );
  }
  Widget _pickupSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: pickupSuggestions.length,
        itemBuilder: (context, index) {
          final place = pickupSuggestions[index];

          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.grey),
            title: Text(
              [
                place['properties']['name'],
                place['properties']['street'],
                place['properties']['city'],
                place['properties']['state'],
                place['properties']['country'],
              ]
                  .where((e) => e != null && e.toString().isNotEmpty)
                  .join(', '),
            ),


            onTap: () {
              final props = place['properties'];

              final selectedText = [
                props['name'],
                props['street'],
                props['city'],
                props['state'],
                props['country'],
              ]
                  .where((e) => e != null && e.toString().isNotEmpty)
                  .join(', ');

              setState(() {
                pickupController.text = selectedText;
                pickupSuggestions.clear();
                showPickupSuggestions = false;
                pickupSelected = true;
              });

              FocusScope.of(context).unfocus();
            },


          );
        },
      ),
    );
  }



  Widget _timeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text(
                'Required Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F2A3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (selectedHours > 1) {
                      setState(() {
                        selectedHours--;
                      });
                    }
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A3A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$selectedHours hour${selectedHours > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2A3A),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (selectedHours < 24) {
                      setState(() {
                        selectedHours++;
                      });
                    }
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select how many hours you need the ride',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBox({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged, // 🔹 ADD THIS
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
              onChanged: onChanged,
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
