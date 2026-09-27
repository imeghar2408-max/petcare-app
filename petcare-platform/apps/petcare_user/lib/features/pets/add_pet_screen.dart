import 'package:flutter/material.dart';
import 'package:petcare_core/petcare_core.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  final _name = TextEditingController();
  final _species = TextEditingController();
  final _breed = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _species.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name and species are required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post('/users/pets', data: {
        'name': _name.text.trim(),
        'species': _species.text.trim(),
        'breed': _breed.text.trim().isEmpty ? null : _breed.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn\'t save pet: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a pet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(
            controller: _species,
            decoration: const InputDecoration(labelText: 'Species (dog, cat, ...)'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _breed, decoration: const InputDecoration(labelText: 'Breed (optional)')),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes — allergies, temperament, etc.'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save pet'),
          ),
        ],
      ),
    );
  }
}
