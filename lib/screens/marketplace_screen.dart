// lib/screens/marketplace_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/colors.dart';
import '../services/api_config.dart';

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
        const SnackBar(content: Text("Please type your question")),
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
          _aiResponse = "AI assistant is busy right now. Please try again in a moment.";
        });
      }
    } catch (e) {
      setState(() {
        _aiResponse = "No internet connection. Please check your network and try again.";
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
        title: const Text("Marketplace", style: TextStyle(color: Colors.white)),
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
                "Available Products",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
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
                        label: const Text("Contact"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Contacting seller for ${p['name']}..."),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  )),

              const SizedBox(height: 40),

              // AI Assistant Section
              const Text(
                "AI Marketplace Assistant",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Ask about prices, best selling time, transport, buyers, or anything!",
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
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
                  hintText: "e.g. What is a good price for broilers in Nairobi today?",
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
                Card(
                  elevation: 4,
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.smart_toy, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              "AI Assistant Reply",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          _aiResponse!,
                          style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textDark),
                        ),
                      ],
                    ),
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