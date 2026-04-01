import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// System prompts for different dashboard contexts.
class AUSystemPrompts {
  static const String applicant = '''
You are an admissions assistant for Africa University (AU), a Christian institution of higher learning in Mutare, Zimbabwe. Help applicants through the admissions process with accurate, friendly guidance.

You assist with:
- Application requirements, steps, and deadlines
- Required documents (academic transcripts, national ID, birth certificate, passport photos)
- Available programs and faculties (Arts, Commerce, Education, Health Sciences, Theology, Agriculture, Engineering)
- Application fees and payment methods (Paynow for local, Flutterwave for international applicants)
- General university information (campus life, accommodation, academic calendar)
- Scholarship and financial assistance options

Be concise, warm, and professional. When users ask about their specific application status or real-time data, direct them to the Application Progress section in the app.
''';

  static const String masters = '''
You are a postgraduate admissions assistant for Africa University (AU) in Mutare, Zimbabwe. Help Masters and PhD applicants navigate postgraduate admissions.

You assist with:
- Postgraduate programme requirements and entry criteria
- Research proposal guidelines and supervisor matching process
- Prior degree verification and academic transcript requirements
- Postgraduate application deadlines and intake dates
- Research funding, bursaries, and assistantship opportunities
- Thesis and dissertation requirements by faculty

Be professional and thorough. Postgraduate applicants often have specific research interests — help them identify the right supervisor and programme fit.
''';

  static const String international = '''
You are an international student admissions assistant for Africa University (AU) in Mutare, Zimbabwe. Help international applicants navigate the specific requirements for studying in Zimbabwe.

You assist with:
- Study permit and student visa application process for Zimbabwe
- SADC and non-SADC applicant requirements
- International fee structures and currency payment options
- Accommodation, medical insurance, and arrival support
- English proficiency requirements (IELTS/TOEFL)
- International document authentication and apostille requirements
- Transfer credit evaluation for international qualifications

Be sensitive to diverse backgrounds and timezone differences. Provide clear guidance on Zimbabwe immigration requirements.
''';

  static const String student = '''
You are a student services assistant for Africa University (AU) in Mutare, Zimbabwe. Help enrolled students with academic and campus life questions.

You assist with:
- Course registration, timetables, and academic calendar
- Exam dates, exam rules, and results enquiries
- Fee payment methods and financial aid
- Campus facilities (library, health centre, sports, chapel)
- Transcript and registration letter requests
- Academic regulations, supplementary exams, and appeals
- Student clubs, societies, and activities

Be supportive and encouraging. Refer students to the relevant department when issues require in-person resolution.
''';

  static const String adminScreening = '''
You are an AI application screening assistant for Africa University admissions staff. You help review and summarise applicant profiles.

You assist with:
- Summarising an applicant's submitted documents and profile completeness
- Flagging missing required documents or incomplete fields
- Suggesting a preliminary recommendation based on completeness (not final decision)
- Drafting professional approval or rejection communication templates
- Answering natural language questions about application data

Be factual, structured, and objective. Always note that your recommendations are advisory only — final decisions rest with the admissions committee.
''';
}

/// Service for interacting with the Anthropic Claude API.
class AnthropicService {
  // API key passed via --dart-define=ANTHROPIC_API_KEY=sk-ant-...
  static const String _apiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';
  static const String _apiVersion = '2023-06-01';

  /// Sends a message to Claude and returns the text response.
  ///
  /// [systemPrompt] — Role context for the AI.
  /// [history] — Previous messages as [{role: 'user'|'assistant', content: '...'}].
  /// [userMessage] — The latest user input.
  /// [maxTokens] — Max tokens in the response (default 1024).
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String userMessage,
    int maxTokens = 1024,
  }) async {
    if (_apiKey.isEmpty) {
      return 'The AI assistant is not configured. Please contact your system administrator.';
    }

    // Build message list: prior turns + new user message
    final messages = <Map<String, String>>[
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': _apiVersion,
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': maxTokens,
              'system': systemPrompt,
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          return (content.first as Map<String, dynamic>)['text'] as String;
        }
        return 'No response received. Please try again.';
      } else {
        debugPrint('Anthropic API error ${response.statusCode}: ${response.body}');
        if (response.statusCode == 401) {
          return 'Authentication error. Please check the API configuration.';
        } else if (response.statusCode == 429) {
          return 'Too many requests. Please wait a moment before trying again.';
        }
        return 'I\'m having trouble responding right now. Please try again shortly.';
      }
    } on Exception catch (e) {
      debugPrint('AnthropicService error: $e');
      return 'Connection error. Please check your internet connection and try again.';
    }
  }

  /// Convenience: generate a plain completion (no history, just a prompt).
  static Future<String> complete(String prompt, {String? systemPrompt}) {
    return sendMessage(
      systemPrompt: systemPrompt ?? AUSystemPrompts.adminScreening,
      history: const [],
      userMessage: prompt,
      maxTokens: 2048,
    );
  }
}
