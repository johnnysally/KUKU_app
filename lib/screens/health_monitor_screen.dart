import 'package:flutter/material.dart';
import '../theme/colors.dart';

class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});

  @override
  State<HealthMonitorScreen> createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  final TextEditingController sickCountController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController medicationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? selectedFlock;
  DateTime selectedDate = DateTime.now();

  List<String> flocks = [
    "Layer Birds",
    "Broilers Batch 1",
    "Kienyeji Batch 2",
  ];

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogTheme(backgroundColor: AppColors.background),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Health Monitor",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.danger,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Record Health Status",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Select Flock
            const Text("Select Flock", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedFlock,
              hint: const Text("Choose flock"),
              items: flocks
                  .map((flock) => DropdownMenuItem(
                        value: flock,
                        child: Text(flock),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedFlock = value),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sick Birds Count
            const Text("Sick Birds", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: sickCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter number of sick birds",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Symptoms
            const Text("Symptoms", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "List symptoms observed",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Temperature
            const Text("Temperature (°C)", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: temperatureController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter temperature",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Medication
            const Text("Medication Given", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: medicationController,
              decoration: InputDecoration(
                hintText: "E.g Antibiotics, Dewormer, Vitamins",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            const Text("Additional Notes", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Add remarks or special observations",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date
            const Text("Date", style: TextStyle(fontSize: 16)),
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
                    Text("${selectedDate.toLocal()}".split(' ')[0]),
                    Icon(Icons.calendar_month, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Save button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: Save health record
              },
              child: const Text(
                "Save Health Report",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          ],
        ),
      ),
    );
  }
}
