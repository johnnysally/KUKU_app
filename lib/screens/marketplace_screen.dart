// lib/screens/marketplace_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/colors.dart';
import '../services/api_config.dart';
import '../widgets/ai_response_card.dart';
import '../widgets/localized_text.dart';
import '../services/locale_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _queryController = TextEditingController();
  String? _aiResponse;
  bool _isLoading = false;

  // Sample products (replace later with real backend or Hive)
  final List<Map<String, dynamic>> products = [
    {"name": "Layer Eggs (Tray)", "price": 420, "stock": 200, "unit": "tray"},
    {"name": "Broiler Chickens", "price": 650, "stock": 80, "unit": "bird"},
    {"name": "Layers Mash (50kg)", "price": 3200, "stock": 150, "unit": "bag"},
    {"name": "Day-Old Chicks", "price": 120, "stock": 1000, "unit": "chick"},
    {"name": "Broiler Finisher (50kg)", "price": 3100, "stock": 90, "unit": "bag"},
    {"name": "Kienyeji Chicks", "price": 150, "stock": 500, "unit": "chick"},
  ];

  Future<void> _askAI() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleService.instance.t('please_type_question'))),
      );
      return;
    }

    if (ApiConfig.apiKey.isEmpty) {
      setState(() {
        _aiResponse = "Error: Missing API key!\n\nRun app with:\nflutter run --dart-define=GROQ_API_KEY=gsk_...";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResponse = null;
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
                  "You are a friendly and expert poultry marketplace assistant in Kenya and East Africa. "
                  "Help farmers buy/sell chickens, eggs, feed, chicks, and equipment. "
                  "Give current realistic prices in KES, suggest fair deals, and share practical tips. "
                  "Be short, clear, and helpful — like talking to a trusted friend."
            },
            {
              "role": "user",
              "content": query,
            }
          ],
          "temperature": 0.8,
          "max_tokens": 500,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String reply = data['choices'][0]['message']['content'] ?? "No response from AI.";
        setState(() {
          _aiResponse = reply.trim();
        });
      } else {
        setState(() {
          _aiResponse = LocaleService.instance.t('ai_busy_try_again');
        });
      }
    } catch (e) {
      setState(() {
        _aiResponse = LocaleService.instance.t('no_internet_try_again');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: LocalizedText('marketplace_title', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText('available_products', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 16),

              // Product Cards
              ...products.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    color: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        p['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Price: KES ${p['price'].toString()} per ${p['unit']}\nStock: ${p['stock']} available",
                          style: TextStyle(color: Colors.grey[700], height: 1.4),
                        ),
                      ),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.message, size: 18),
                        label: LocalizedText('contact'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(LocaleService.instance.t('contacting_seller', {'name': p['name']})),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  )),

              const SizedBox(height: 40),

              // AI Assistant Section
              LocalizedText('ai_marketplace_title', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text(LocaleService.instance.t('ai_marketplace_hint'), style: TextStyle(color: Colors.grey[600], fontSize: 15)),
              const SizedBox(height: 16),

              // Query Input
              TextField(
                controller: _queryController,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _askAI(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  hintText: LocaleService.instance.t('marketplace_hint_example'),
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                          )
                        : Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _isLoading ? null : _askAI,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // AI Response
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (_aiResponse != null)
                ValueListenableBuilder(
                  valueListenable: LocaleService.instance.languageCode,
                  builder: (_, __, ___) => AIResponseCard(
                    title: LocaleService.instance.t('ai_assistant_reply'),
                    content: _aiResponse!,
                    icon: Icons.smart_toy,
                    backgroundColor: Colors.amber.shade50,
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}