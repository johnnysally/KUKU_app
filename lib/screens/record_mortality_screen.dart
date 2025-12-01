import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecordMortalityScreen extends StatefulWidget {
  const RecordMortalityScreen({super.key});

  @override
  State<RecordMortalityScreen> createState() => _RecordMortalityScreenState();
}

class _RecordMortalityScreenState extends State<RecordMortalityScreen> {
  final TextEditingController numberController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  String? selectedFlock;
  DateTime selectedDate = DateTime.now();

  List<String> flocks = [
    "Layer Birds",
    "Broilers Batch 1",
    "Kienyeji Batch 2",
  ];

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.accent,
            onSurface: AppColors.textDark,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Record Mortality",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              "Add Mortality Record",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 25),

            // Select Flock
            const Text("Select Flock", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              hint: const Text("Choose flock"),
              value: selectedFlock,
              items: flocks.map((flock) {
                return DropdownMenuItem(value: flock, child: Text(flock));
              }).toList(),
              onChanged: (value) => setState(() => selectedFlock = value),
            ),
            const SizedBox(height: 20),

            // Number of Birds
            const Text("Number of Birds Dead", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                hintText: "Enter number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date Picker
            const Text("Date of Mortality", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${selectedDate.toLocal()}".split(' ')[0], style: const TextStyle(color: AppColors.textDark)),
                    const Icon(Icons.calendar_month, color: AppColors.textDark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Reason
            const Text("Reason (Optional)", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                hintText: "Short description...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final count = int.tryParse(numberController.text.trim());
                if (selectedFlock == null || count == null || count <= 0) {
                  messenger.showSnackBar(const SnackBar(content: Text('Please select flock and enter a valid number')));
                  return;
                }
                final box = Hive.box('mortality');
                await box.add({
                  'flock': selectedFlock,
                  'count': count,
                  'date': selectedDate.toIso8601String(),
                  'reason': reasonController.text.trim(),
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (!mounted) return;
                numberController.clear();
                reasonController.clear();
                setState(() => selectedFlock = null);
                messenger.showSnackBar(const SnackBar(content: Text('Mortality record saved')));
              },
              child: const Text(
                "Save Record",
                style: TextStyle(fontSize: 18, color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
