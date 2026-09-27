import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';
import '../booking/provider_list_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../support/support_screen.dart';
import '../../core/app_messenger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final pages = [const _ServiceGrid(), const MyBookingsScreen()];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Bookings'),
        ],
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare'),
        actions: [
          IconButton(
            tooltip: 'Support',
            icon: const Icon(Icons.support_agent_outlined),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: ServiceType.values.map((s) => _ServiceCard(service: s)).toList(),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceType service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProviderListScreen(serviceType: service)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets, size: 32),
              const SizedBox(height: 8),
              Text(service.label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
