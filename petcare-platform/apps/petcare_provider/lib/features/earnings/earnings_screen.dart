import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';

class EarningsSummary {
  final int totalInr;
  final int count;
  final List<Booking> bookings;
  EarningsSummary({required this.totalInr, required this.count, required this.bookings});
}

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<EarningsSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<EarningsSummary> _load() async {
    final res = await _api.get('/providers/earnings');
    return EarningsSummary(
      totalInr: res.data['totalInr'],
      count: res.data['count'],
      bookings: (res.data['bookings'] as List).map((e) => Booking.fromJson(e)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: FutureBuilder<EarningsSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) return const Center(child: Text('Couldn\'t load earnings.'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Total earned', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '₹${data.totalInr}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('${data.count} completed job${data.count == 1 ? '' : 's'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Statement', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (data.bookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No paid jobs yet.'),
                )
              else
                ...data.bookings.map(
                  (b) => Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text('${b.serviceType.label} · ${b.petName ?? 'Pet'}'),
                      subtitle: Text(DateFormat('MMM d, y').format(b.scheduledAt)),
                      trailing: Text('₹${b.priceInr}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              // Payouts (transferring earnings to the provider's bank/UPI)
              // aren't automated in this scaffold — the backend has a Payout
              // table ready for a periodic payout job (e.g. weekly via
              // Razorpay Route/Payouts), which is a good Phase 6 addition.
            ],
          );
        },
      ),
    );
  }
}
