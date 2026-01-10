import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'call_confirmation_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  String currentLocationText = 'Detecting location…';

  final TextEditingController destinationController = TextEditingController();
  List<dynamic> placeSuggestions = [];
  bool placeSelected = false;

  Timer? _debounce; // 🔹 debounce timer

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    destinationController.dispose();
    super.dispose();
  }

  // ---------------- LOCATION ----------------

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        currentLocationText = 'Location permission denied';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentLocation = userLatLng;
      currentLocationText = 'Fetching address…';
    });

    _mapController.move(userLatLng, 16);
    _getAddressFromLatLng(userLatLng);
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
          '?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json',
    );

    final response =
    await http.get(url, headers: {'User-Agent': 'taxi-app'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['address'];

      final locality =
          address['suburb'] ?? address['neighbourhood'] ?? '';
      final city = address['city'] ?? address['town'] ?? '';

      setState(() {
        currentLocationText =
        locality.isNotEmpty ? '$locality, $city' : data['display_name'];
      });
    }
  }

  // ---------------- SEARCH (FIXED) ----------------

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        placeSuggestions = [];
        placeSelected = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
          '?q=$query&format=json&addressdetails=1&limit=6',
    );

    final response =
    await http.get(url, headers: {'User-Agent': 'taxi-app'});

    if (response.statusCode == 200) {
      setState(() {
        placeSuggestions = json.decode(response.body);
        placeSelected = false;
      });
    }
  }

  // ---------------- CALL ----------------

  Future<void> _callAdminNumber() async {
    const adminNumber = '+919876543210';
    final uri = Uri(scheme: 'tel', path: adminNumber);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onRequestRide() {
    if (!placeSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
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
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(10.0, 76.0),
                  initialZoom: 13,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.taxi_app_user',
                  ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.redAccent, size: 32),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // TOP SEARCH
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _searchBar(),
                  const SizedBox(height: 8),
                  _pickupLocationPill(),
                  if (placeSuggestions.isNotEmpty) _suggestionsCard(),
                ],
              ),
            ),

            // BOTTOM CTA
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: GestureDetector(
                  onTap: _onRequestRide,
                  child: _requestRideButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.search),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: destinationController,
              onChanged: onSearchChanged, // 🔹 FIXED
              decoration: const InputDecoration(
                hintText: 'Where are you going?',
                border: InputBorder.none,
              ),
            ),
          ),
          if (destinationController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  destinationController.clear();
                  placeSuggestions = [];
                  placeSelected = false;
                });
              },
              child: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _pickupLocationPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Pickup: $currentLocationText',
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _suggestionsCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: placeSuggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final place = placeSuggestions[index];
            return ListTile(
              title: Text(place['display_name'], maxLines: 2),
              onTap: () {
                setState(() {
                  destinationController.text = place['display_name'];
                  placeSuggestions = [];
                  placeSelected = true;
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _requestRideButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A3A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(
        child: Text('Request Ride',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
