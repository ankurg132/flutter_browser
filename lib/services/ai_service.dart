import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  AIService() {
    OpenAI.apiKey = dotenv.env['OPENAI_API_KEY']!;
    if (dotenv.env['OPENAI_BASE_URL'] != null &&
        dotenv.env['OPENAI_BASE_URL']!.isNotEmpty) {
      OpenAI.baseUrl = dotenv.env['OPENAI_BASE_URL']!;
    }
  }

  Future<String> summarizeText(String text) async {
    try {
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "You are a helpful assistant that summarizes text.",
          ),
        ],
        role: OpenAIChatMessageRole.system,
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Summarize the following text:\n\n$text",
          ),
        ],
        role: OpenAIChatMessageRole.user,
      );

      final completion = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [systemMessage, userMessage],
      );

      return completion.choices.first.message.content?.first.text ??
          'Unable to generate summary.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> translateText(String text, String targetLanguage) async {
    try {
      if (dotenv.env['OPENAI_API_KEY'] == null ||
          dotenv.env['OPENAI_API_KEY']!.isEmpty) {
        // Mock translation for demo purposes or if key is missing
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Simulate network delay
        return "[$targetLanguage Translation] $text";
      }

      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "You are a helpful assistant that translates text.",
          ),
        ],
        role: OpenAIChatMessageRole.system,
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Translate the following text to $targetLanguage:\n\n$text",
          ),
        ],
        role: OpenAIChatMessageRole.user,
      );

      final completion = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [systemMessage, userMessage],
      );

      return completion.choices.first.message.content?.first.text ??
          'Unable to translate text.';
    } catch (e) {
      // Fallback to mock translation on error for robustness during demo
      return "[$targetLanguage Translation (Fallback)] $text";
    }
  }
}
