import 'package:flutter/material.dart';
import 'report_issue_screen.dart';
import 'my_reports_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // Bumping this forces MyReportsScreen to rebuild (and re-fetch) right
  // after a new report is submitted from the other tab.
  int _reportsRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Support'),
          bottom: const TabBar(tabs: [Tab(text: 'My reports'), Tab(text: 'New report')]),
        ),
        body: TabBarView(
          children: [
            MyReportsScreen(key: ValueKey(_reportsRefreshKey)),
            ReportIssueForm(onSubmitted: () => setState(() => _reportsRefreshKey++)),
          ],
        ),
      ),
    );
  }
}
