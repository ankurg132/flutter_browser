import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // TODO: Replace with a secure way to handle API keys or prompt user
  static const String _apiKey = 'YOUR_API_KEY';
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
  }

  Future<String> summarizeText(String text) async {
    final content = [Content.text('Summarize the following text:\n\n$text')];
    final response = await _model.generateContent(content);
    return response.text ?? 'Unable to generate summary.';
  }

  Future<String> translateText(String text, String targetLanguage) async {
    final content = [
      Content.text('Translate the following text to $targetLanguage:\n\n$text'),
    ];
    final response = await _model.generateContent(content);
    return response.text ?? 'Unable to translate text.';
  }
}
