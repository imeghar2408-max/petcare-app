import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petcare_core/petcare_core.dart';

class ProviderTrackingScreen extends StatefulWidget {
  final Booking booking;
  const ProviderTrackingScreen({super.key, required this.booking});

  @override
  State<ProviderTrackingScreen> createState() => _ProviderTrackingScreenState();
}

class _ProviderTrackingScreenState extends State<ProviderTrackingScreen> {
  late BookingSocket _socket;
  StreamSubscription<Position>? _positionSub;
  LatLng? _myLocation;
  String? _alertText;

  @override
  void initState() {
    super.initState();
    _socket = BookingSocket(
      baseUrl: ApiConfig.baseUrl,
      namespace: 'location',
      bookingId: widget.booking.id,
    );
    _socket.socket.on('location:alert', (data) {
      final inside = data['inside'] == true;
      setState(() {
        _alertText = inside
            ? null
            : '⚠️ You\'ve left the safe zone (${data['distanceM']}m from center, limit ${data['radiusM']}m). Consider heading back.';
      });
    });
    _startSendingLocation();
  }

  Future<void> _startSendingLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
      _socket.socket.emit('location:update', {
        'bookingId': widget.booking.id,
        'lat': pos.latitude,
        'lng': pos.longitude,
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final hasSafeZone = b.safeZoneLat != null && b.safeZoneLng != null;
    final safeZoneCenter =
        hasSafeZone ? LatLng(b.safeZoneLat!, b.safeZoneLng!) : LatLng(b.lat, b.lng);

    return Scaffold(
      appBar: AppBar(title: Text('${b.serviceType.label} · ${b.petName ?? 'Pet'}')),
      body: Column(
        children: [
          if (_alertText != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(_alertText!, style: TextStyle(color: Colors.red.shade900)),
            ),
          if (!hasSafeZone)
            Container(
              width: double.infinity,
              color: Colors.amber.shade50,
              padding: const EdgeInsets.all(12),
              child: const Text('The owner hasn\'t set a safe zone for this booking yet.'),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: safeZoneCenter, zoom: 15),
              myLocationEnabled: true,
              circles: hasSafeZone
                  ? {
                      Circle(
                        circleId: const CircleId('safeZone'),
                        center: safeZoneCenter,
                        radius: b.safeZoneRadiusM!.toDouble(),
                        fillColor: Colors.orange.withOpacity(0.15),
                        strokeColor: Colors.orange,
                        strokeWidth: 2,
                      ),
                    }
                  : {},
              markers: {
                if (_myLocation != null)
                  Marker(markerId: const MarkerId('me'), position: _myLocation!),
              },
            ),
          ),
        ],
      ),
    );
  }
}
