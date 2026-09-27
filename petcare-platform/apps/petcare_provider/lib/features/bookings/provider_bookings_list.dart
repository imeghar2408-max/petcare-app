import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../tracking/tracking_screen.dart';
import '../chat/chat_screen.dart';
import '../support/report_issue_screen.dart';

/// Shows a filtered slice of the provider's bookings with the right action
/// buttons for that status (Accept/Reject for REQUESTED, Start/Complete for
/// ACCEPTED/IN_PROGRESS).
class ProviderBookingsList extends StatefulWidget {
  final List<BookingStatus> statuses;
  final String emptyText;

  const ProviderBookingsList({super.key, required this.statuses, required this.emptyText});

  @override
  State<ProviderBookingsList> createState() => _ProviderBookingsListState();
}

class _ProviderBookingsListState extends State<ProviderBookingsList> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Booking>> _load() async {
    final res = await _api.get('/bookings/mine');
    final all = (res.data as List).map((e) => Booking.fromJson(e)).toList();
    return all.where((b) => widget.statuses.contains(b.status)).toList();
  }

  Future<void> _refresh() async => setState(() => _future = _load());

  Future<void> _respond(Booking b, bool accept) async {
    await _api.post('/bookings/${b.id}/respond', data: {'accept': accept});
    _refresh();
  }

  Future<void> _start(Booking b) async {
    await _api.post('/bookings/${b.id}/start');
    _refresh();
  }

  Future<void> _complete(Booking b) async {
    await _api.post('/bookings/${b.id}/complete');
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
              children: [Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(widget.emptyText)))],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = bookings[i];
              final isTrackable = b.status == BookingStatus.accepted ||
                  b.status == BookingStatus.inProgress;
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
                          Text('${b.serviceType.label} · ${b.petName ?? 'Pet'}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (isTrackable)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.map_outlined),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProviderTrackingScreen(booking: b)),
                                  ),
                                ),
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
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEE, MMM d · h:mm a').format(b.scheduledAt)),
                      Text('${b.addressText}'),
                      Text('Owner: ${b.otherPartyName ?? '-'} · ₹${b.priceInr}'),
                      const SizedBox(height: 10),
                      _actionsFor(b),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionsFor(Booking b) {
    switch (b.status) {
      case BookingStatus.requested:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _respond(b, false),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _respond(b, true),
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case BookingStatus.accepted:
        return ElevatedButton(
          onPressed: () => _start(b),
          child: const Text('Start job'),
        );
      case BookingStatus.inProgress:
        return ElevatedButton(
          onPressed: () => _complete(b),
          child: const Text('Mark complete'),
          // Once tapped, the user app should be prompted to pay
          // (POST /payments/create-order) — wire that up in Phase 4.
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
