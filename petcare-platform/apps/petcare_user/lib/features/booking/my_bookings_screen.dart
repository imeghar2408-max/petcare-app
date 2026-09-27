import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../tracking/tracking_screen.dart';
import '../chat/chat_screen.dart';
import '../payments/payment_flow.dart';
import '../reviews/rate_provider_screen.dart';
import '../support/report_issue_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Booking>> _load() async {
    final res = await _api.get('/bookings/mine');
    return (res.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<void> _refresh() async => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Booking>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No bookings yet — go book a service!')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _BookingCard(booking: bookings[i], onChanged: _refresh),
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onChanged;
  const _BookingCard({required this.booking, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final isTrackable = b.status == BookingStatus.accepted || b.status == BookingStatus.inProgress;
    final needsPayment = b.status == BookingStatus.completed && b.paymentStatus != PaymentStatus.paid;
    final needsReview = b.status == BookingStatus.completed &&
        b.paymentStatus == PaymentStatus.paid &&
        !b.hasReview;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('${b.serviceType.label} · ${b.petName ?? 'Pet'}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _StatusChip(status: b.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEE, MMM d · h:mm a').format(b.scheduledAt)}\n'
              'with ${b.otherPartyName ?? 'provider'} · ₹${b.priceInr}',
            ),
            if (isTrackable || needsPayment || needsReview) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (isTrackable) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Track'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TrackingScreen(booking: b)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(booking: b)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Report an issue',
                      icon: const Icon(Icons.flag_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportIssueScreen(booking: b)),
                      ),
                    ),
                  ],
                  if (needsPayment)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => PaymentFlow.start(context, b),
                        child: const Text('Pay Now'),
                      ),
                    ),
                  if (needsReview)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RateProviderScreen(booking: b)),
                        ),
                        child: const Text('Rate provider'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  const _StatusChip({required this.status});

  Color _color() {
    switch (status) {
      case BookingStatus.requested:
        return Colors.orange;
      case BookingStatus.accepted:
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Chip(
      label: Text(status.label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      visualDensity: VisualDensity.compact,
    );
  }
}
