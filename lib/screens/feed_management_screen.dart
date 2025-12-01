// lib/screens/feed_management_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';
import '../services/api_config.dart';

class FeedManagementScreen extends StatefulWidget {
  const FeedManagementScreen({super.key});

  @override
  State<FeedManagementScreen> createState() => _FeedManagementScreenState();
}

class _FeedManagementScreenState extends State<FeedManagementScreen> {
  final TextEditingController stockAmountController = TextEditingController();
  final TextEditingController consumedController = TextEditingController();
  final TextEditingController flockSizeController = TextEditingController();
  final TextEditingController birdAgeController = TextEditingController();
  final TextEditingController avgWeightController = TextEditingController();

  String? selectedFeedType;
  String? selectedFlock;
  String? productionGoal;
  DateTime selectedDate = DateTime.now();

  bool _isGenerating = false;
  String? _generatedProgram;
  String? _calculatedFeed;

  final List<String> feedTypes = [
    "Chick Mash",
    "Growers Mash",
    "Layers Mash",
    "Finisher Pellets",
    "Broiler Starter",
    "Broiler Finisher",
  ];

  final List<String> flocks = [
    "Layer Birds",
    "Broilers Batch 1",
    "Broilers Batch 2",
    "Kienyeji Improved",
    "Local Chickens",
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _generateFeedingProgram() async {
    if (selectedFlock == null ||
        selectedFeedType == null ||
        flockSizeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select flock, feed type, and enter flock size')),
      );
      return;
    }

    if (ApiConfig.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key missing! Run with --dart-define=GROQ_API_KEY=...')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedProgram = null;
    });

    final prompt = '''
Generate a practical weekly feeding program for poultry farmers in Kenya/East Africa.

Flock: $selectedFlock
Feed Type: $selectedFeedType
Number of birds: ${flockSizeController.text}
Age: ${birdAgeController.text.isEmpty ? "Not specified" : "${birdAgeController.text} weeks"}
Average weight: ${avgWeightController.text.isEmpty ? "Not specified" : "${avgWeightController.text} kg"}
Goal: ${productionGoal ?? "General health & growth"}

Please provide in simple bullet points:
• Daily feed per bird and total for flock
• Weekly and monthly totals
• Feeding times (morning/evening)
• Clean water needs
• Any local supplements or tips
Use easy English for small-scale farmers.
''';

    try {
      final modelToUse = ApiConfig.isDefaultModelDecommissioned() ? ApiConfig.fastModel : ApiConfig.defaultModel;
      if (ApiConfig.isDefaultModelDecommissioned()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Configured model is deprecated — using fallback model.')),
          );
        }
      }

      final response = await http.post(
        Uri.parse(ApiConfig.chatEndpoint),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": modelToUse,
          "messages": [
            {
              "role": "system",
              "content": "You are an experienced poultry nutritionist helping farmers in Kenya, Uganda, Tanzania, and East Africa. Give accurate, affordable, and practical feeding advice using locally available feeds."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
          "max_tokens": 800,
        }),
      ).timeout(const Duration(seconds: 40));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String result = data['choices'][0]['message']['content'] ?? "No response.";
        setState(() => _generatedProgram = result.trim());
      } else {
        setState(() {
          _generatedProgram = "Failed to connect to AI.\nError ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _generatedProgram = "No internet or server error.\nPlease try again.";
      });
    } finally {
      setState(() => _isGenerating = false); // Fixed: removed invalid if()
    }
  }

  void _calculateQuickFeed() {
    final size = int.tryParse(flockSizeController.text) ?? 0;
    final weight = double.tryParse(avgWeightController.text) ?? 0.0;

    if (size <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid flock size and average weight')),
      );
      return;
    }

    final dailyPerBirdGrams = (weight * 1000 * 0.035).round();
    final dailyTotalKg = (dailyPerBirdGrams * size) / 1000;
    final weeklyKg = dailyTotalKg * 7;
    final monthlyKg = dailyTotalKg * 30;

    setState(() {
      _calculatedFeed = '''
Quick Feed Estimate:
• Per bird daily: $dailyPerBirdGrams grams
• Total daily: ${dailyTotalKg.toStringAsFixed(2)} kg
• Weekly total: ${weeklyKg.toStringAsFixed(1)} kg
• Monthly (30 days): ${monthlyKg.toStringAsFixed(1)} kg
• Tip: Split into 2 meals — morning and evening
''';
    });
  }

  Future<void> _saveGeneratedProgram() async {
    if (_generatedProgram == null) return;

    final box = await Hive.openBox('feed_programs');
    await box.add({
      'type': 'program',
      'flock': selectedFlock,
      'feedType': selectedFeedType,
      'flockSize': flockSizeController.text,
      'birdAge': birdAgeController.text,
      'avgWeight': avgWeightController.text,
      'goal': productionGoal,
      'program': _generatedProgram,
      'savedAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feeding program saved!')),
      );
    }
  }

  Future<void> _saveStock() async {
    final amount = double.tryParse(stockAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid stock amount')),
      );
      return;
    }

    final box = await Hive.openBox('feed_stock');
    await box.add({
      'type': 'stock',
      'amountKg': amount,
      'feedType': selectedFeedType,
      'flock': selectedFlock,
      'date': selectedDate.toIso8601String(),
    });

    stockAmountController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock recorded')),
      );
    }
  }

  Future<void> _saveConsumption() async {
    final amount = double.tryParse(consumedController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid consumption')),
      );
      return;
    }

    final box = await Hive.openBox('feed_consumption');
    await box.add({
      'type': 'consumption',
      'amountKg': amount,
      'flock': selectedFlock,
      'date': selectedDate.toIso8601String(),
    });

    consumedController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumption recorded')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed Management", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI Feeding Program Generator",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 20),

            _buildDropdown("Select Flock", selectedFlock, flocks, (v) => selectedFlock = v),
            const SizedBox(height: 16),
            _buildDropdown("Feed Type", selectedFeedType, feedTypes, (v) => selectedFeedType = v),
            const SizedBox(height: 16),

            _buildTextField(flockSizeController, "Flock Size (birds)", TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(birdAgeController, "Bird Age (weeks)", TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(avgWeightController, "Average Weight (kg)", TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),

            _buildDropdown("Production Goal", productionGoal, const [
              'Egg Production',
              'Meat (Broilers)',
              'Growth',
              'General Health'
            ], (v) => productionGoal = v),

            const SizedBox(height: 30),

            // Generate AI Program
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateFeedingProgram,
                icon: _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? "Generating..." : "Generate AI Program"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _calculateQuickFeed,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text("Quick Feed Calculator"),
              ),
            ),

            if (_calculatedFeed != null) ...[
              const SizedBox(height: 20),
              _resultCard("Quick Calculation", _calculatedFeed!),
            ],

            if (_generatedProgram != null) ...[
              const SizedBox(height: 20),
              _resultCard("AI Feeding Program", _generatedProgram!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveGeneratedProgram,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Program"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                ),
              ),
            ],

            // Saved feeding programs moved to dedicated screen

            const SizedBox(height: 40),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 20),

            const Text(
              "Record Feed Stock & Usage",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            _buildTextField(stockAmountController, "Add New Stock (kg)", TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(consumedController, "Daily Consumption (kg)", TextInputType.number),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveStock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Save Stock", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveConsumption,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text("Save Consumption", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text("Choose ${label.toLowerCase()}"),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => onChanged(v)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _resultCard(String title, String content) {
    return Card(
      elevation: 4,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 15.5, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    stockAmountController.dispose();
    consumedController.dispose();
    flockSizeController.dispose();
    birdAgeController.dispose();
    avgWeightController.dispose();
    super.dispose();
  }
}