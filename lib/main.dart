import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'chat_screen.dart';  // Add this at the top of main.dart

void main() {
  runApp(CommunityApp());
}

class CommunityApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ZoneSelectionScreen(),
    );
  }
}

// ZoneManager to detect zones
class ZoneManager {
  final List<Map<String, dynamic>> zones = [
    {
      'location': LatLng(19.11682291960689, 72.85820376764977),
      'radius': 5000.0,
      'name': 'Mumbai: Western',
      'description': 'Join the conversation for Western Mumbai',
    },
    {
      'location': LatLng(18.978407148241164, 72.83090094869995),
      'radius': 5000.0,
      'name': 'Mumbai: S & C',
      'description': 'Discuss topics from South & Central Mumbai',
    },
    {
      'location': LatLng(19.03258344806578, 73.02638524451197),
      'radius': 5000.0,
      'name': 'Navi Mumbai',
      'description': 'Stay connected in Navi Mumbai',
    },
    {
      'location': LatLng(19.216115511140767, 72.98148404855603),
      'radius': 5000.0,
      'name': 'Thane',
      'description': 'Connect with people in Thane',
    },
    {
      'location': LatLng(19.240464909951175, 73.12866930084701),
      'radius': 5000.0,
      'name': 'Kalyan',
      'description': 'Engage with the Kalyan community',
    },
    {
      'location': LatLng(19.29678011960183, 73.20310776112292),
      'radius': 5000.0,
      'name': 'Titwala',
      'description': 'Join discussions from Titwala',
    },
  ];

  List<Map<String, dynamic>> getNearbyZones(LatLng userLocation) {
    List<Map<String, dynamic>> nearbyZones = [];
    for (var zone in zones) {
      double distance = Distance().as(
        LengthUnit.Meter,
        userLocation,
        zone['location'],
      );

      if (distance <= zone['radius']) {
        nearbyZones.add(zone);
      }
    }
    return nearbyZones;
  }
}

class ZoneSelectionScreen extends StatefulWidget {
  @override
  _ZoneSelectionScreenState createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  final Location _location = Location();
  final ZoneManager _zoneManager = ZoneManager();
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _nearbyZones = [];

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location services are enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        print("Location services are disabled.");
        return;
      }
    }

    // Request permission if not already granted
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print("Location permission denied.");
        return;
      }
    }

    // Fetch the user's location once
    LocationData locationData = await _location.getLocation();
    _updateUserLocation(locationData);

    // Listen for location updates
    _location.onLocationChanged.listen((LocationData newLocation) {
      _updateUserLocation(newLocation);
    });
  }

  void _updateUserLocation(LocationData locationData) {
    if (locationData.latitude != null && locationData.longitude != null) {
      LatLng newLocation = LatLng(locationData.latitude!, locationData.longitude!);
      List<Map<String, dynamic>> newZones = _zoneManager.getNearbyZones(newLocation);

      setState(() {
        _currentLocation = newLocation;
        _nearbyZones = newZones;
      });

      print("Updated Location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink.shade900,
        title: Center(
          child: Text(
            'COMMUNITY',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif', // Try using a serif-style font if needed
              color: Colors.white,
              letterSpacing: 2, // Adds spacing for better readability
            ),
          ),
        ),
        elevation: 0, // Removes shadow for a clean look
        automaticallyImplyLeading: false, // Removes back button if not needed
      ),

      body: _nearbyZones.isEmpty
          ? Center(child: Text("You are not in any defined chat zone"))
          : ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: _nearbyZones.length,
        itemBuilder: (context, index) {
          var zone = _nearbyZones[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen(zoneName: zone['name'])),
              );
            },
            child: ZoneCard(zoneName: zone['name'], description: zone['description']),
          );
        },
      ),
    );
  }
}

// Zone Card UI
class ZoneCard extends StatelessWidget {
  final String zoneName;
  final String description;

  ZoneCard({required this.zoneName, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.pink[50],
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.pink.shade900, size: 40),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zoneName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
