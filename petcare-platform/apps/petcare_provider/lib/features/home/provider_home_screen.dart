import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../bookings/provider_bookings_list.dart';
import '../earnings/earnings_screen.dart';
import '../support/support_screen.dart';
import '../../core/app_messenger.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    PushService.register(
      ApiClient(baseUrl: ApiConfig.baseUrl),
      onForegroundMessage: (message) {
        final text = message.notification?.body;
        if (text != null) showAppSnackBar(text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const _JobsTab(), const EarningsScreen()];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Earnings'),
        ],
      ),
    );
  }
}

class _JobsTab extends StatefulWidget {
  const _JobsTab();

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> with SingleTickerProviderStateMixin {
  bool _isAvailable = false;
  late final ApiClient _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late final TabController _tabController = TabController(length: 2, vsync: this);
  double? _ratingAvg;
  int? _ratingCount;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final me = await _api.post('/auth/me');
    final provider = me.data['providerProfile'];
    if (provider != null && mounted) {
      setState(() {
        _ratingAvg = (provider['ratingAvg'] as num).toDouble();
        _ratingCount = provider['ratingCount'];
        _isAvailable = provider['isAvailable'] ?? false;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);
    // TODO: grab current GPS position (geolocator) and include lat/lng
    // so /providers/nearby can find this provider.
    await _api.post('/providers/availability', data: {'isAvailable': value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PetCare Provider'),
            if (_ratingAvg != null) ...[
              const SizedBox(width: 10),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              Text(' ${_ratingAvg!.toStringAsFixed(1)} (${_ratingCount})',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Requests'), Tab(text: 'Active jobs')],
        ),
        actions: [
          IconButton(
            tooltip: 'Support',
            icon: const Icon(Icons.support_agent_outlined),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(_isAvailable ? 'Online' : 'Offline'),
                Switch(value: _isAvailable, onChanged: _toggleAvailability),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProviderBookingsList(
            statuses: const [BookingStatus.requested],
            emptyText: _isAvailable
                ? 'No new requests right now.'
                : 'You\'re offline — go online to receive requests.',
          ),
          const ProviderBookingsList(
            statuses: [BookingStatus.accepted, BookingStatus.inProgress],
            emptyText: 'No active jobs right now.',
          ),
        ],
      ),
    );
  }
}
