// lib/screens/disease_detection_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/colors.dart';
import '../services/api_config.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _aiResult;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _detectDisease() async {
    if (_imageFile == null && _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a photo or describe symptoms")),
      );
      return;
    }

    if (ApiConfig.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing API key! Run with --dart-define=GROQ_API_KEY=...")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResult = null;
    });

    try {
      // Convert image to base64
      String? base64Image;
      String? mimeType;

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(bytes);
        mimeType = 'image/jpeg'; // image_picker saves as JPEG
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": ApiConfig.visionModel, // Supports images!
          // Or use: "llama-3.2-90b-vision-preview" for better accuracy
          "messages": [
            {
              "role": "system",
              "content": "You are a poultry disease expert in Africa. Analyze the chicken photo and symptoms. "
                  "Diagnose possible diseases (e.g. Newcastle, Coccidiosis, Fowl Pox, IBD/Gumboro). "
                  "Give: 1) Likely disease 2) Confidence 3) Symptoms match 4) Recommended treatment 5) Prevention. "
                  "Use simple language for farmers."
            },
            {
              "role": "user",
              "content": [
                if (base64Image != null)
                  {
                    "type": "image_url",
                    "image_url": {
                      "url": "data:$mimeType;base64,$base64Image"
                    }
                  },
                {
                  "type": "text",
                  "text": _descriptionController.text.trim().isEmpty
                      ? "Analyze this chicken photo for disease."
                      : "Symptoms: ${_descriptionController.text.trim()}\n\nAlso analyze the photo."
                }
              ]
            }
          ],
          "temperature": 0.5,
          "max_tokens": 600,
        }),
      ).timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String result = data['choices'][0]['message']['content'] ?? "No diagnosis returned.";
        setState(() {
          _aiResult = result.trim();
        });
      } else {
        setState(() {
          _aiResult = "Failed to analyze image.\nError ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResult = "Error: Check internet or try again.\n$e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disease Detection", style: TextStyle(color: Colors.white)),
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
              "AI Disease Detector",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              "Take or upload a photo of sick bird + describe symptoms",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 25),

            // Image Picker
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 12),
                          Text("Tap to add photo", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Change Photo"),
                  onPressed: _showImageSourceDialog,
                ),
              ),
            ],
            const SizedBox(height: 25),

            // Symptoms Input
            const Text("Describe Symptoms (Optional but helps AI)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "E.g. watery droppings, swollen eyes, not eating, sudden death...",
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Detect Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.health_and_safety),
                label: Text(_isLoading ? "Analyzing Photo..." : "Detect Disease Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _detectDisease,
              ),
            ),
            const SizedBox(height: 30),

            // Result
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_aiResult != null)
              Card(
                elevation: 4,
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.medical_information, color: Colors.red),
                          SizedBox(width: 10),
                          Text("AI Diagnosis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 30),
                      Text(
                        _aiResult!,
                        style: const TextStyle(fontSize: 16.5, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}