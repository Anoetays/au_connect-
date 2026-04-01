import 'package:google_generative_ai/google_generative_ai.dart';

/// Stateful Gemini chat session for the AU Connect chatbot screens.
/// Each instance maintains its own conversation history internally.
class AIChatService {
  // API key passed via --dart-define=GEMINI_API_KEY=...
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  late final ChatSession _chat;

  AIChatService({required String systemPrompt}) {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(systemPrompt),
    );
    _chat = model.startChat();
  }

  /// Sends [message] to Gemini and returns the response text.
  /// The chat session retains history automatically.
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ??
          'Sorry, I could not process that. Please try again.';
    } catch (e) {
      return 'Sorry, something went wrong. Please try again.';
    }
  }
}
