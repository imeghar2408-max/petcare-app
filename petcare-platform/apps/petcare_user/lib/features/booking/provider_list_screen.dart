import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import 'booking_form_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final ServiceType serviceType;
  const ProviderListScreen({super.key, required this.serviceType});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<List<ProviderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ProviderSummary>> _load() async {
    // TODO: pass the pet owner's actual lat/lng (from geolocator or their
    // saved address) instead of placeholder Delhi coordinates.
    final res = await _api.get('/providers/nearby', query: {
      'serviceType': _backendName(widget.serviceType),
      'lat': 28.6139,
      'lng': 77.2090,
    });
    return (res.data as List).map((e) => ProviderSummary.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.serviceType.label} providers')),
      body: FutureBuilder<List<ProviderSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Couldn\'t load providers: ${snapshot.error}'));
          }
          final providers = snapshot.data ?? [];
          if (providers.isEmpty) {
            return const Center(child: Text('No providers available nearby right now.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = providers[i];
              final offering = p.offeringFor(widget.serviceType);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        p.profilePhoto != null ? NetworkImage(p.profilePhoto!) : null,
                    child: p.profilePhoto == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(' ${p.ratingAvg.toStringAsFixed(1)} (${p.ratingCount})'),
                      if (offering != null) Text('  ·  ₹${offering.priceInr}'),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: offering == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingFormScreen(
                                provider: p,
                                serviceType: widget.serviceType,
                                offering: offering,
                              ),
                            ),
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Converts Dart's camelCase enum name to the backend's SCREAMING_SNAKE_CASE.
String _backendName(ServiceType type) {
  final name = type.name;
  final buffer = StringBuffer();
  for (int i = 0; i < name.length; i++) {
    final char = name[i];
    if (char == char.toUpperCase() && i != 0) buffer.write('_');
    buffer.write(char.toUpperCase());
  }
  return buffer.toString();
}
