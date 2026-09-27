import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petcare_core/petcare_core.dart';

class TrackingScreen extends StatefulWidget {
  final Booking booking;
  const TrackingScreen({super.key, required this.booking});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late BookingSocket _socket;
  GoogleMapController? _mapController;

  // Safe zone state — defaults to the booking's service address, or the
  // provider's already-saved safe zone if one exists.
  late LatLng _safeZoneCenter;
  double _safeZoneRadiusM = 300;
  bool _editingZone = false;
  bool _savingZone = false;

  LatLng? _providerLocation;
  String? _alertText;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _safeZoneCenter = LatLng(
      b.safeZoneLat ?? b.lat,
      b.safeZoneLng ?? b.lng,
    );
    _safeZoneRadiusM = (b.safeZoneRadiusM ?? 300).toDouble();

    _socket = BookingSocket(baseUrl: ApiConfig.baseUrl, namespace: 'location', bookingId: b.id);
    _socket.socket.on('location:broadcast', (data) {
      setState(() {
        _providerLocation = LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble());
      });
    });
    _socket.socket.on('location:alert', (data) {
      final inside = data['inside'] == true;
      setState(() {
        _alertText = inside
            ? null
            : '⚠️ ${widget.booking.otherPartyName ?? 'Provider'} has left the safe zone (${data['distanceM']}m from center, limit ${data['radiusM']}m)';
      });
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  Future<void> _saveSafeZone() async {
    setState(() => _savingZone = true);
    try {
      await _api.post('/bookings/${widget.booking.id}/safe-zone', data: {
        'lat': _safeZoneCenter.latitude,
        'lng': _safeZoneCenter.longitude,
        'radiusM': _safeZoneRadiusM.round(),
      });
      if (mounted) {
        setState(() => _editingZone = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Safe zone saved')));
      }
    } finally {
      if (mounted) setState(() => _savingZone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Scaffold(
      appBar: AppBar(
        title: Text('${b.serviceType.label} · ${b.petName ?? 'Pet'}'),
        actions: [
          IconButton(
            tooltip: _editingZone ? 'Cancel editing' : 'Edit safe zone',
            icon: Icon(_editingZone ? Icons.close : Icons.edit_location_alt),
            onPressed: () => setState(() => _editingZone = !_editingZone),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_alertText != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(_alertText!, style: TextStyle(color: Colors.red.shade900)),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _safeZoneCenter, zoom: 15),
              onMapCreated: (c) => _mapController = c,
              onTap: _editingZone
                  ? (pos) => setState(() => _safeZoneCenter = pos)
                  : null,
              circles: {
                Circle(
                  circleId: const CircleId('safeZone'),
                  center: _safeZoneCenter,
                  radius: _safeZoneRadiusM,
                  fillColor: Colors.orange.withOpacity(0.15),
                  strokeColor: Colors.orange,
                  strokeWidth: 2,
                ),
              },
              markers: {
                Marker(
                  markerId: const MarkerId('safeZoneCenter'),
                  position: _safeZoneCenter,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  infoWindow: const InfoWindow(title: 'Safe zone center'),
                ),
                if (_providerLocation != null)
                  Marker(
                    markerId: const MarkerId('provider'),
                    position: _providerLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: InfoWindow(title: b.otherPartyName ?? 'Provider'),
                  ),
              },
            ),
          ),
          if (_editingZone)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Radius'),
                      Expanded(
                        child: Slider(
                          min: 50,
                          max: 2000,
                          divisions: 39,
                          value: _safeZoneRadiusM,
                          label: '${_safeZoneRadiusM.round()} m',
                          onChanged: (v) => setState(() => _safeZoneRadiusM = v),
                        ),
                      ),
                      Text('${_safeZoneRadiusM.round()} m'),
                    ],
                  ),
                  const Text(
                    'Tap the map to move the center. This defines the area your provider is expected to stay within.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _savingZone ? null : _saveSafeZone,
                    child: _savingZone
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save safe zone'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
