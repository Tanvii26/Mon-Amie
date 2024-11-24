import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  final GenerativeModel model;
  final List<Map<String, String>> _chatHistory =
      []; // Store the conversation history
  bool _initPromptSent = false;
  // Constructor that accepts a pre-initialized GenerativeModel
  AiService({required this.model});

  // Getter for chat history
  List<Map<String, String>> get chatHistory => _chatHistory;

  // Method to add a prompt and response to the history
  void _addToHistory(String prompt, String response) {
    _chatHistory.add({'prompt': prompt, 'response': response});
  }

  // Method to format chat history for better context when generating content
  String _getChatHistoryContext() {
    String context = '';
    for (var entry in _chatHistory) {
      context += 'User: ${entry['prompt']}\nAI: ${entry['response']}\n\n';
    }
    return context;
  }

  // Method to send a prompt and keep track of history
  Future<String> isPrompt(String prompt) async {
    try {
      if (!_initPromptSent) {
        await setInitialPrompt();
        _initPromptSent = true;
      }
      // Get the chat history context as part of the input for better responses
      String context = _getChatHistoryContext();

      // Append the current prompt to the context
      context += 'User: $prompt\n';
      await Future.delayed(const Duration(seconds: 1));

      // Send the prompt along with the history context
      final response = await model.generateContent(
        [
          Content.text(context), // Include entire history as context
        ],
      );

      // Save the prompt and the generated response to history
      String aiResponse = response.text ?? 'No response from AI';
      _addToHistory(prompt, aiResponse);

      return aiResponse;
    } catch (e) {
      return 'Error: ${e.toString()}'; // Return error message in case of failure
    }
  }

  Future<String> setInitialPrompt() async {
    const String initialPrompt =
        "Answer the upcoming questions from perspective of Computer Science User and as per latest updates. Answer to the point unless asked to explain.";
    return await isPrompt(initialPrompt);
  }
}
