// lib/screens/tips_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/colors.dart';
import '../services/api_config.dart';
import '../widgets/ai_response_card.dart';
import '../widgets/localized_text.dart';
import '../services/locale_service.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;
  String? _aiTip;

  List<String> get generalTips => LocaleService.instance.t('general_tips_bullets').split('\n');

  Future<void> _getAITip() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    // Safety check - remind developer if key not passed
    if (ApiConfig.apiKey.isEmpty || ApiConfig.apiKey == 'YOUR_KEY_NOT_SET') {
      setState(() {
        _aiTip = LocaleService.instance.t('api_key_missing');
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
          SnackBar(content: Text(LocaleService.instance.t('model_deprecated_msg'))),
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleService.instance.t('tip_saved'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: LocalizedText('tips_title', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText('general_tips_bullets', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
              LocalizedText('ask_ai_personalized', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 10),
              TextField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: LocaleService.instance.t('tip_hint_example'),
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
                    ValueListenableBuilder(
                      valueListenable: LocaleService.instance.languageCode,
                      builder: (_, __, ___) => AIResponseCard(
                        title: LocaleService.instance.t('ai_tip_title'),
                        content: _aiTip!,
                        icon: Icons.lightbulb_outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveTip,
                          icon: const Icon(Icons.save_alt),
                          label: LocalizedText('save_tip'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => _aiTip = null),
                          child: LocalizedText('dismiss'),
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