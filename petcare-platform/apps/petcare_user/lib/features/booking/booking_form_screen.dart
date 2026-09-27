import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../pets/add_pet_screen.dart';
import 'my_bookings_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final ProviderSummary provider;
  final ServiceType serviceType;
  final ProviderServiceOffering offering;

  const BookingFormScreen({
    super.key,
    required this.provider,
    required this.serviceType,
    required this.offering,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  List<Pet> _pets = [];
  Pet? _selectedPet;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool _loadingPets = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final res = await _api.get('/users/pets');
    setState(() {
      _pets = (res.data as List).map((e) => Pet.fromJson(e)).toList();
      _selectedPet = _pets.isNotEmpty ? _pets.first : null;
      _loadingPets = false;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_selectedPet == null || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick a pet and enter an address')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.post('/bookings', data: {
        'petId': _selectedPet!.id,
        'providerId': widget.provider.id,
        'serviceType': _backendName(widget.serviceType),
        'scheduledAt': _scheduledAt.toIso8601String(),
        'addressText': _addressController.text.trim(),
        // TODO: geocode the address text (or use device GPS) for real lat/lng.
        'lat': 28.6139,
        'lng': 77.2090,
        'notes': _notesController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent! We\'ll notify you when the provider responds.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Couldn\'t send request: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.provider.name}')),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text('${widget.serviceType.label} · ₹${widget.offering.priceInr}'),
                    subtitle: Text('${widget.offering.durationMin} min · with ${widget.provider.name}'),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Which pet?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_pets.isEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a pet first'),
                    onPressed: () async {
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const AddPetScreen()),
                      );
                      if (added == true) _loadPets();
                    },
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: _pets
                        .map((pet) => ChoiceChip(
                              label: Text(pet.name),
                              selected: _selectedPet?.id == pet.id,
                              onSelected: (_) => setState(() => _selectedPet = pet),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 20),
                Text('When?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(DateFormat('EEE, MMM d · h:mm a').format(_scheduledAt)),
                  onPressed: _pickDateTime,
                ),
                const SizedBox(height: 20),
                Text('Where?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: 'Full address'),
                ),
                const SizedBox(height: 20),
                Text('Notes for the provider (optional)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Anything they should know?'),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send Request'),
                ),
              ],
            ),
    );
  }
}

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
