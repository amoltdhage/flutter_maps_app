import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class OpenStreetMapScreen extends StatefulWidget {
  @override
  State<OpenStreetMapScreen> createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<OpenStreetMapScreen> {
  Location location = Location();
  LatLng? currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check service enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    // Check permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // Get static initial location
    var userLocation = await location.getLocation();
    setState(() {
      currentPosition = LatLng(userLocation.latitude!, userLocation.longitude!);
    });

    // Listen for live location updates
    location.onLocationChanged.listen((newLoc) {
      setState(() {
        currentPosition = LatLng(newLoc.latitude!, newLoc.longitude!);
      });

      // Move map with user
      _mapController.move(currentPosition!, 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Live Location Map")),
      body: currentPosition == null
          ? Center(child: CircularProgressIndicator()) // Loading state
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition!, // dynamic location
                initialZoom: 15,
              ),
              children: [
                // 👇 FREE SAFE TILE PROVIDER (NOT BLOCKED)
                TileLayer(
                  urlTemplate:
                      "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),

                // 📌 Live Moving Marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition!,
                      width: 60,
                      height: 60,
                      child: Icon(
                        Icons.location_pin,
                        size: 45,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
