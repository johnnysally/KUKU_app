import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecordEggsScreen extends StatefulWidget {
  const RecordEggsScreen({super.key});

  @override
  State<RecordEggsScreen> createState() => _RecordEggsScreenState();
}

class _RecordEggsScreenState extends State<RecordEggsScreen> {
  final TextEditingController totalEggsController = TextEditingController();
  final TextEditingController brokenEggsController = TextEditingController();

  String? selectedFlock;
  String? selectedTime;
  DateTime selectedDate = DateTime.now();

  List<String> flocks = ["Layer Birds", "Broilers Batch 1", "Kienyeji Batch 2"];
  List<String> times = ["Morning", "Afternoon", "Evening"];

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary, // header background
            onPrimary: AppColors.accent, // header text color
            onSurface: AppColors.textDark, // body text color
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
          "Record Eggs",
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
            const Text(
              "Add Egg Collection Record",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 30),

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
              value: selectedFlock,
              hint: const Text("Choose flock"),
              items: flocks.map((flock) => DropdownMenuItem(value: flock, child: Text(flock))).toList(),
              onChanged: (value) => setState(() => selectedFlock = value),
            ),
            const SizedBox(height: 20),

            // Total Eggs
            const Text("Total Eggs Collected", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: totalEggsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                hintText: "Enter total eggs",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Broken Eggs
            const Text("Broken/Cracked Eggs", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: brokenEggsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                hintText: "Enter broken eggs",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Collection Time
            const Text("Collection Time", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
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
              value: selectedTime,
              hint: const Text("Select time"),
              items: times.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (value) => setState(() => selectedTime = value),
            ),
            const SizedBox(height: 20),

            // Date Picker
            const Text("Date", style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 30),

            // Save Button
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
                final total = int.tryParse(totalEggsController.text.trim());
                final broken = int.tryParse(brokenEggsController.text.trim()) ?? 0;
                if (selectedFlock == null || total == null || total < 0) {
                  messenger.showSnackBar(const SnackBar(content: Text('Please select flock and enter total eggs')));
                  return;
                }
                final box = Hive.box('eggs');
                await box.add({
                  'flock': selectedFlock,
                  'totalEggs': total,
                  'brokenEggs': broken,
                  'timePeriod': selectedTime,
                  'date': selectedDate.toIso8601String(),
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (!mounted) return;
                totalEggsController.clear();
                brokenEggsController.clear();
                setState(() {
                  selectedFlock = null;
                  selectedTime = null;
                });
                messenger.showSnackBar(const SnackBar(content: Text('Eggs record saved')));
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
