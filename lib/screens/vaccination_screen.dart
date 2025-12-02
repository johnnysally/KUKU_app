import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/locale_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';

class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({super.key});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  String? selectedFlock;
  String? selectedVaccine;
  DateTime selectedDate = DateTime.now();
  DateTime? nextVaccinationDate;
  final TextEditingController notesController = TextEditingController();

  List<String> flocks = ["Layer Birds", "Broilers Batch 1", "Kienyeji Batch 2"];
  List<String> vaccines = [
    "Newcastle Disease",
    "Gumboro",
    "Fowl Pox",
    "Marek's Disease",
    "Avian Influenza"
  ];

  Future<void> pickDate(BuildContext context, bool isNext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext ? (nextVaccinationDate ?? DateTime.now()) : selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        if (isNext) {
          nextVaccinationDate = picked;
        } else {
          selectedDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(LocaleService.instance.t('vaccination_title'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleService.instance.t('record_vaccination'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 30),

            // Select Flock
            Text(LocaleService.instance.t('select_flock'), style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              ),
              value: selectedFlock,
              hint: Text(LocaleService.instance.t('choose_flock')),
              items: flocks.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (value) => setState(() => selectedFlock = value),
            ),
            const SizedBox(height: 20),

            // Select Vaccine
            Text(LocaleService.instance.t('select_vaccine'), style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              ),
              value: selectedVaccine,
              hint: Text(LocaleService.instance.t('choose_vaccine')),
              items: vaccines.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (value) => setState(() => selectedVaccine = value),
            ),
            const SizedBox(height: 20),

            // Vaccination Date
            Text(LocaleService.instance.t('date_of_vaccination'), style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pickDate(context, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardBackground,
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

            // Next Vaccination Reminder
            Text(LocaleService.instance.t('next_vaccination_optional'), style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => pickDate(context, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardBackground,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nextVaccinationDate != null ? "${nextVaccinationDate!.toLocal()}".split(' ')[0] : "Select date",
                      style: const TextStyle(color: AppColors.textDark),
                    ),
                    const Icon(Icons.calendar_month, color: AppColors.textDark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            Text(LocaleService.instance.t('notes_optional'), style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
                decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardBackground,
                hintText: LocaleService.instance.t('add_remarks'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (selectedFlock == null || selectedVaccine == null) {
                    messenger.showSnackBar(SnackBar(content: Text(LocaleService.instance.t('please_select_flock_and_vaccine'))));
                    return;
                  }

                  final vbox = Hive.box('vaccinations');
                  final record = {
                    'flock': selectedFlock,
                    'vaccine': selectedVaccine,
                    'date': selectedDate.toIso8601String(),
                    'nextDate': nextVaccinationDate?.toIso8601String(),
                    'notes': notesController.text.trim(),
                    'createdAt': DateTime.now().toIso8601String(),
                  };

                  await vbox.add(record);

                  // If next vaccination date set, schedule a reminder and persist it
                  if (nextVaccinationDate != null) {
                    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
                    final title = 'Vaccination Reminder';
                    final body = '${selectedVaccine!} for ${selectedFlock!}';
                    // schedule using NotificationService (in-app fallback)
                    await NotificationService.instance.scheduleNotification(id, title, body, nextVaccinationDate!);
                    // persist metadata in notifications box so it appears in the Notifications screen
                    final notifBox = Hive.box('notifications');
                    await notifBox.add({
                      'id': id,
                      'title': title,
                      'body': body,
                      'scheduledAt': nextVaccinationDate!.toIso8601String(),
                    });
                  }

                  if (!mounted) return;
                  // clear inputs
                  setState(() {
                    selectedFlock = null;
                    selectedVaccine = null;
                    nextVaccinationDate = null;
                    notesController.clear();
                    selectedDate = DateTime.now();
                  });
                  messenger.showSnackBar(SnackBar(content: Text(LocaleService.instance.t('vaccination_saved'))));
                },
                child: Text(LocaleService.instance.t('save_vaccination'), style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
