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
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  bool isSearching = false;
  bool isWaitingForApproval = false;

  String currentLocationText = 'Fetching location...';
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
      currentLocationText =
      '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
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

    setState(() {
      isWaitingForApproval = true;
    });

    // backend request goes here later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Taxi App',
          style: TextStyle(
            color: const Color(0xFF0F2A3A),
            fontSize: 25,
            fontWeight: FontWeight.bold,fontStyle: FontStyle.italic
          ),
        ),
      ),
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

          Positioned(
            top: 1,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const SizedBox(height: 18),

                if (!isSearching)
                  GestureDetector(
                    onTap: () => setState(() => isSearching = true),
                    child: _singleSearchBar(),
                  ),

                if (isSearching) ...[
                  _locationDisplayCard(
                    icon: Icons.my_location,
                    text: currentLocationText,
                  ),
                  const SizedBox(height: 12),
                  _destinationInputCard(),
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
              child: _requestRideButton(),
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

  Widget _waitingApprovalCard() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF0F2A3A),
          ),
          const SizedBox(height: 16),
          const Text(
            'Waiting for approval',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2A3A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your ride request has been sent.\nPlease wait for admin confirmation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                isWaitingForApproval = false;
                placeSelected = false;
              });
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'Cancel Request',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationDisplayCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _destinationInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 14),

          Expanded(
            child: TextField(
              controller: destinationController,
              onChanged: searchPlaces,
              decoration: const InputDecoration(
                hintText: 'Enter your destination',
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
                FocusScope.of(context).unfocus();
              },
              child: const Icon(
                Icons.close,
                size: 20,
                color: Colors.black45,
              ),
            ),
        ],
      ),
    );
  }

  Widget _suggestionList() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
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
    );
  }

  Widget _singleSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.black54),
          SizedBox(width: 12),
          Text('Search destination'),
        ],
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
        child: Text(
          'Request Ride',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }


}
