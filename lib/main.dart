import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:telephony_sms/telephony_sms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(WaySecure());
}

class WaySecure extends StatefulWidget {
  @override
  _WaySecureState createState() => _WaySecureState();
}

class _WaySecureState extends State<WaySecure> {
  final Location _location = Location();
  final TelephonySMS _telephonySMS = TelephonySMS();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  LatLng? _currentLocation;
  final Set<String> _notifiedZones = {}; // Track notified zones
  String? _currentZone; // Track the current zone user is in

  // Define zones
  final List<Map<String, dynamic>> unsafeZones = [
    {
      'location': LatLng(19.11682291960689, 72.85820376764977),
      'radius': 5000.0,
      'name': 'Mumbai: Western',
    },
    {
      'location': LatLng(18.978407148241164, 72.83090094869995),
      'radius': 5000.0,
      'name': 'Mumbai: S & C',
    },
    {
      'location': LatLng(19.03258344806578, 73.02638524451197),
      'radius': 5000.0,
      'name': 'Navi Mumbai',
    },
    {
      'location': LatLng(19.216115511140767, 72.98148404855603),
      'radius': 5000.0,
      'name': 'Thane',
    },
    {
      'location': LatLng(19.240464909951175, 73.12866930084701),
      'radius': 5000.0,
      'name': 'Kalyan',
    },
    {
      'location': LatLng(19.29678011960183, 73.20310776112292),
      'radius': 5000.0,
      'name': 'Titwala',
    },
  ];
//hello
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _initializeNotifications();
    await _fetchInitialLocation();
    _trackUserLocation();
  }

  Future<void> _requestPermissions() async {
    await Permission.sms.request();
    await Permission.location.request();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  void _trackUserLocation() {
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        final LatLng userLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        for (var zone in unsafeZones) {
          final LatLng zoneLocation = zone['location'];
          final double zoneRadius = zone['radius'];
          final double distance = Distance().as(LengthUnit.Meter, userLocation, zoneLocation);

          final String zoneName = zone['name'];

          if (distance <= zoneRadius && !_notifiedZones.contains(zoneName)) {
            _sendLocationSMS(zone);
            _sendLocalNotification(zone);
            _notifiedZones.add(zoneName);
          }

          if (distance <= zoneRadius) {
            setState(() {
              _currentZone = zoneName;
            });
          }
        }

        setState(() {
          _currentLocation = userLocation;
        });
      }
    });
  }

  Future<void> _sendLocalNotification(Map<String, dynamic> zone) async {
    await _notifications.show(
      1,
      "Unsafe Zone Alert",
      "You have entered ${zone['name']}! Stay cautious.",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "unsafe_zone_channel",
          "Unsafe Zone Notifications",
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _sendLocationSMS(Map<String, dynamic> zone) async {
    if (_currentLocation != null) {
      String message = "Alert! You have entered ${zone['name']}. This area is unsafe! Be safe.";
      try {
        await _telephonySMS.requestPermission();
        await _telephonySMS.sendSMS(phone: "9321486739", message: message);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location sent via SMS!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send SMS: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to fetch location.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pink.shade900,
          title: Center(child: Text('COMMUNITY')),
        ),
        body: Column(
          children: [
            Expanded(
              child: _currentLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  maxZoom: 17.0,
                  minZoom: 10.0,
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  CircleLayer(
                    circles: unsafeZones.map((zone) {
                      return CircleMarker(
                        point: zone['location'],
                        color: Colors.red.withOpacity(0.5),
                        radius: zone['radius'] / 10,
                      );
                    }).toList(),
                  ),
                  MarkerLayer(
                    markers: [
                      if (_currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          width: 40.0,
                          height: 40.0,
                          child: Icon(Icons.location_on, color: Colors.blueAccent, size: 40.0),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_currentZone != null) ZoneChatCard(zoneName: _currentZone!)
          ],
        ),
      ),
    );
  }
}

// Zone-Based Chat Widget
class ZoneChatCard extends StatelessWidget {
  final String zoneName;
  ZoneChatCard({required this.zoneName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.pink.shade100,
      child: ListTile(
        leading: Icon(Icons.chat_bubble, color: Colors.pink.shade700, size: 30),
        title: Text(zoneName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        subtitle: Text("Join the conversation for $zoneName"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(communityName: zoneName)),
          );
        },
      ),
    );
  }
}

// Chat Screen
class ChatScreen extends StatelessWidget {
  final String communityName;
  ChatScreen({required this.communityName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(communityName), backgroundColor: Colors.pink.shade900),
      body: Center(child: Text("Chat Screen for $communityName", style: TextStyle(fontSize: 20))),
    );
  }
}
