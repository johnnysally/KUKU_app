import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';

class RecordFlockScreen extends StatefulWidget {
  const RecordFlockScreen({super.key});

  @override
  State<RecordFlockScreen> createState() => _RecordFlockScreenState();
}

class _RecordFlockScreenState extends State<RecordFlockScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _birdType;

  final List<String> _types = [
    'Layer',
    'Broiler',
    'Kienyeji',
    'Breeder',
    'Mixed',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final count = int.tryParse(_countController.text.trim());
    final age = double.tryParse(_ageController.text.trim());
    if (name.isEmpty || _birdType == null || count == null || count <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Please provide flock name, type and a valid count')));
      return;
    }
    final box = Hive.box('flocks');
    await box.add({
      'name': name,
      'type': _birdType,
      'count': count,
      'avgAgeWeeks': age,
      'notes': _notesController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    _nameController.clear();
    _countController.clear();
    _ageController.clear();
    _notesController.clear();
    setState(() => _birdType = null);
    messenger.showSnackBar(const SnackBar(content: Text('Flock saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Record Flock'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Flock Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              labelText: 'Flock Name',
              filled: true,
              fillColor: AppColors.cardBackground,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(filled: true, fillColor: AppColors.cardBackground, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary))),
            value: _birdType,
            hint: const Text('Bird Type'),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _birdType = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countController,
            cursorColor: AppColors.primary,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Number of Birds', filled: true, fillColor: AppColors.cardBackground, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageController,
            cursorColor: AppColors.primary,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Average Age (weeks)', filled: true, fillColor: AppColors.cardBackground, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(labelText: 'Notes (optional)', filled: true, fillColor: AppColors.cardBackground, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary))),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              child: const Text('Save Flock', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
