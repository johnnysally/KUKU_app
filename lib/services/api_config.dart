// lib/services/api_config.dart

class ApiConfig {
  /// Groq API Key - NEVER hardcode it!
  /// Run with: flutter run --dart-define=GROQ_API_KEY=gsk_...
  static const String apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// Real Groq endpoint (same for text & vision)
  static const String chatEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Models - pick the best one for each screen
  // Allow overriding models via --dart-define to avoid hardcoded names
  static const String defaultModel = String.fromEnvironment(
    'GROQ_DEFAULT_MODEL',
    defaultValue: 'llama-3.3-70b-versatile', // Replacement for deprecated llama-3.1-70b-versatile
  );

  static const String fastModel = String.fromEnvironment(
    'GROQ_FAST_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );

  static const String visionModel = String.fromEnvironment(
    'GROQ_VISION_MODEL',
    defaultValue: 'llama-3.2-11b-vision-preview',
  );
  // Alternative vision model (more accurate but slower):
  // static const String visionModel = 'llama-3.2-90b-vision-preview';

  /// Helper: check if key is set (optional, for debug)
  static bool get hasApiKey => apiKey.isNotEmpty && apiKey != '';

  /// Known decommissioned models (update as needed)
  static const List<String> decommissionedModels = [
    'llama-3.1-70b-versatile',
  ];

  /// Returns true if the configured default model appears in the decommissioned list
  static bool isDefaultModelDecommissioned() => decommissionedModels.contains(defaultModel);
}