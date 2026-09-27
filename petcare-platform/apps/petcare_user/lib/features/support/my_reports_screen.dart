import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late Future<List<Complaint>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Complaint>> _load() async {
    final res = await _api.get('/complaints/mine');
    return (res.data as List).map((e) => Complaint.fromJson(e)).toList();
  }

  Future<void> _refresh() async => setState(() => _future = _load());

  Color _statusColor(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.open:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
      case ComplaintStatus.closed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Complaint>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('You haven\'t reported anything — hopefully it stays that way!')),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = reports[i];
              final color = _statusColor(r.status);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(r.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Chip(
                            label: Text(r.status.label, style: TextStyle(color: color, fontSize: 12)),
                            backgroundColor: color.withOpacity(0.1),
                            side: BorderSide(color: color.withOpacity(0.3)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.category.label,
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      Text(r.description),
                      Text(DateFormat('MMM d, y').format(r.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (r.adminNote != null) ...[
                        const Divider(height: 20),
                        Text('Response from support', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 2),
                        Text(r.adminNote!),
                      ],
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
}
