import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';

/// The actual form, with no Scaffold/AppBar of its own so it can be embedded
/// either inside SupportScreen's "New report" tab or pushed standalone (see
/// ReportIssueScreen below) — same widget, two places to reach it from.
class ReportIssueForm extends StatefulWidget {
  final Booking? booking;
  final VoidCallback? onSubmitted;
  const ReportIssueForm({super.key, this.booking, this.onSubmitted});

  @override
  State<ReportIssueForm> createState() => _ReportIssueFormState();
}

class _ReportIssueFormState extends State<ReportIssueForm> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  ComplaintCategory _category = ComplaintCategory.serviceQuality;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill in a subject and description')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.post('/complaints', data: {
        'category': backendEnumName(_category.name),
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        if (widget.booking != null) 'bookingId': widget.booking!.id,
      });
      if (mounted) {
        _subjectController.clear();
        _descriptionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted — our team will follow up.')),
        );
        widget.onSubmitted?.call();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn\'t submit: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.booking != null)
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'About: ${widget.booking!.serviceType.label} · ${widget.booking!.petName ?? 'Pet'} '
                'with ${widget.booking!.otherPartyName ?? '-'}',
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('What kind of issue is this?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ComplaintCategory.values
              .map((c) => ChoiceChip(
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Text('Subject', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectController,
          decoration: const InputDecoration(hintText: 'Short summary'),
        ),
        const SizedBox(height: 20),
        Text('What happened?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'As much detail as you can share'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit report'),
        ),
      ],
    );
  }
}

/// Standalone version with its own Scaffold/AppBar — used when opened
/// directly from a specific booking's card (pops back with a result once
/// submitted, rather than living inside SupportScreen's tabs).
class ReportIssueScreen extends StatelessWidget {
  final Booking? booking;
  const ReportIssueScreen({super.key, this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: ReportIssueForm(
        booking: booking,
        onSubmitted: () => Navigator.pop(context, true),
      ),
    );
  }
}
