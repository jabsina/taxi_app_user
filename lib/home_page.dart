import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  bool isSearching = false;

  String currentLocationText = "Fetching location...";
  final TextEditingController destinationController = TextEditingController();

  List<dynamic> placeSuggestions = [];
  bool placeSelected = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        currentLocationText = "Location permission denied";
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentLocation = userLatLng;
      currentLocationText =
      "${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}";
    });

    _mapController.move(userLatLng, 16);
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        placeSuggestions = [];
        placeSelected = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
          '?q=$query&format=json&addressdetails=1&limit=5',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'taxi-app'},
    );

    if (response.statusCode == 200) {
      setState(() {
        placeSuggestions = json.decode(response.body);
        placeSelected = false;
      });
    }
  }

  void _onRequestRide() {
    FocusScope.of(context).unfocus();

    if (!placeSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid destination')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ride request sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F2F8),

      // 👈 LEFT SLIDE DRAWER
      drawer: _buildDrawer(),

      body: Stack(
        children: [
          FlutterMap(
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.taxi_app_user',
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ☰ Hamburger Button
          Positioned(
            top: 44,
            left: 16,
            child: GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A3A),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A3A),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    'Taxi App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                if (!isSearching)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isSearching = true;
                      });
                    },
                    child: _singleSearchBar(),
                  ),

                if (isSearching) ...[
                  _inputCard(
                    icon: Icons.my_location,
                    enabled: false,
                    hint: currentLocationText,
                  ),
                  const SizedBox(height: 12),
                  _inputCard(
                    icon: Icons.search,
                    enabled: true,
                    hint: 'Enter your destination',
                    controller: destinationController,
                    onChanged: searchPlaces,
                    onClear: () {
                      setState(() {
                        destinationController.clear();
                        placeSuggestions = [];
                        placeSelected = false;
                      });
                    },
                  ),
                  if (placeSuggestions.isNotEmpty) _suggestionList(),
                ],
              ],
            ),
          ),

          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: _onRequestRide,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A3A),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    'Request Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            ListTile(
              leading: const Icon(
                Icons.person,
                color: const Color(0xFF0F2A3A),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: const Color(0xFF0F2A3A),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Profile page later
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.history,
                color: const Color(0xFF0F2A3A),
              ),
              title: const Text(
                'History',
                style: TextStyle(
                  color: const Color(0xFF0F2A3A),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to History page later
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _singleSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.black54),
          SizedBox(width: 12),
          Text('Search destination',
              style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _inputCard({
    required IconData icon,
    required bool enabled,
    required String hint,
    TextEditingController? controller,
    Function(String)? onChanged,
    VoidCallback? onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
          if (onClear != null &&
              controller != null &&
              controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _suggestionList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 220,
        child: ListView.separated(
          itemCount: placeSuggestions.length,
          separatorBuilder: (_, __) =>
          const Divider(height: 1),
          itemBuilder: (context, index) {
            final place = placeSuggestions[index];
            return ListTile(
              title: Text(
                place['display_name'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
}
