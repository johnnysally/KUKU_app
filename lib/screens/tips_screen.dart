// lib/screens/tips_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';
import '../services/api_config.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;
  String? _aiTip;

  final List<String> generalTips = [
    "Maintain clean drinking water for your birds daily.",
    "Separate sick birds immediately to prevent disease spread.",
    "Ensure proper ventilation in poultry houses.",
    "Provide balanced feed according to bird age.",
    "Regularly check for parasites and vaccinate on schedule.",
  ];

  Future<void> _getAITip() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    // Safety check - remind developer if key not passed
    if (ApiConfig.apiKey.isEmpty || ApiConfig.apiKey == 'YOUR_KEY_NOT_SET') {
      setState(() {
        _aiTip = "Error: Missing Groq API key!\n\nRun with:\nflutter run --dart-define=GROQ_API_KEY=gsk_...";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _aiTip = null;
    });

    try {
      final modelToUse = ApiConfig.isDefaultModelDecommissioned() ? ApiConfig.fastModel : ApiConfig.defaultModel;
      if (ApiConfig.isDefaultModelDecommissioned() && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configured model is deprecated — using fallback model.')),
        );
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
              "content":
                  "You are a friendly and expert poultry farming advisor for African farmers. "
                  "Give short, practical, and actionable advice in simple English. "
                  "Use local examples when possible."
            },
            {
              "role": "user",
              "content": question,
            }
          ],
          "temperature": 0.7,
          "max_tokens": 600,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String reply = data['choices'][0]['message']['content'] ?? "No reply";
        setState(() {
          _aiTip = reply.trim();
        });
      } else {
        debugPrint('Groq Error: ${response.statusCode} ${response.body}');
        setState(() {
          _aiTip = "AI is busy right now. Please try again in a moment.\n(${response.statusCode})";
        });
      }
    } catch (e) {
      debugPrint('Request failed: $e');
      setState(() {
        _aiTip = "No internet connection or server error. Please check your network.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTip() async {
    if (_aiTip == null || _aiTip!.trim().isEmpty) return;
    final box = await Hive.openBox('ai_tips');
    await box.add({
      'tip': _aiTip,
      'savedAt': DateTime.now().toIso8601String(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tip saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Tips & Advice", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "General Tips",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              ...generalTips.map(
                (tip) => Card(
                  color: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline, color: AppColors.primary),
                    title: Text(tip, style: const TextStyle(color: AppColors.textDark)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Ask AI for Personalized Advice",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "E.g. How to improve egg production this season?",
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send, color: _isLoading ? Colors.grey : AppColors.primary),
                    onPressed: _isLoading ? null : _getAITip,
                  ),
                ),
                onSubmitted: (_) => _getAITip(),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_aiTip != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Text(
                        _aiTip!,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveTip,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save Tip'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => _aiTip = null),
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Saved tips moved to a dedicated screen
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}