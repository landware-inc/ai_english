// lib/services/claude_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation_model.dart';
import '../utils/logger.dart';

class ClaudeService {
  final String _apiKey;
  final String _baseUrl = 'https://api.anthropic.com/v1';
  final String _model = 'claude-3-opus-20240229'; // Choose the appropriate Claude model

  ClaudeService({required String apiKey}) : _apiKey = apiKey;

  // Headers for Claude API
  Map<String, String> get _headers => {
    'x-api-key': _apiKey,
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  };

  // Process a conversation message with Claude
  Future<String> processConversation({
    required List<Message> messages,
    required String systemPrompt,
    bool enableSpeechImprovement = true,
  }) async {
    try {
      // Convert our messages to Claude's format
      final claudeMessages = _formatMessagesForClaude(messages);

      // Enhance system prompt if speech improvement is enabled
      final enhancedSystemPrompt = enableSpeechImprovement
          ? '$systemPrompt\n\nPay attention to the user\'s English and provide natural corrections when appropriate. Mark corrections with [correct: your suggestion] and pronunciation tips with [pronunciation: tip].'
          : systemPrompt;

      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: _headers,
        body: jsonEncode({
          'model': _model,
          'system': enhancedSystemPrompt,
          'messages': claudeMessages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['content'][0]['text'];
      } else {
        Logger.error('Claude API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to process message: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error processing conversation: $e');
      throw Exception('Error processing conversation: $e');
    }
  }

  // Process QA evaluation
  Future<Map<String, dynamic>> evaluateQAResponse({
    required String question,
    required String userAnswer,
    required List<String> correctAnswers,
    required List<String> keywords,
  }) async {
    try {
      final systemPrompt = '''
      You are evaluating a user's answer to a practice question. 
      Compare the user's answer to the correct answers and determine if it's correct.
      Consider both exact matches and answers that contain the key concepts/keywords.
      If the answer is partially correct or incorrect, provide specific feedback and suggestions.
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: _headers,
        body: jsonEncode({
          'model': _model,
          'system': systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': '''
              Question: $question
              User's answer: $userAnswer
              Correct answers: ${correctAnswers.join(' | ')}
              Important keywords: ${keywords.join(', ')}
              
              Evaluate whether the user's answer is correct. Return a JSON object with:
              1. "isCorrect": boolean
              2. "feedback": string with evaluation
              3. "suggestedAnswers": array of 1-2 correct answers that are most appropriate
              '''
            }
          ],
          'max_tokens': 1024,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiResponse = responseData['content'][0]['text'];

        // Extract JSON from the response
        final jsonStart = aiResponse.indexOf('{');
        final jsonEnd = aiResponse.lastIndexOf('}') + 1;

        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = aiResponse.substring(jsonStart, jsonEnd);
          return jsonDecode(jsonString);
        } else {
          // Fallback if JSON parsing fails
          return {
            'isCorrect': false,
            'feedback': 'Unable to evaluate answer properly. Please try again.',
            'suggestedAnswers': correctAnswers.take(2).toList(),
          };
        }
      } else {
        Logger.error('Claude API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to evaluate answer: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error evaluating QA response: $e');
      throw Exception('Error evaluating QA response: $e');
    }
  }

  // Send audio for transcription and analysis
  Future<Map<String, dynamic>> processSpeech(String audioFilePath) async {
    // Note: This is a placeholder for integration with Claude's speech API
    // You would need to implement this based on Claude's audio processing API
    // when it becomes available

    try {
      // Placeholder implementation
      throw UnimplementedError('Speech processing with Claude not yet implemented');
    } catch (e) {
      Logger.error('Error processing speech: $e');
      throw Exception('Error processing speech: $e');
    }
  }

  // Helper method to format messages for Claude API
  List<Map<String, dynamic>> _formatMessagesForClaude(List<Message> messages) {
    return messages.map((message) {
      return {
        'role': message.role == MessageRole.user ? 'user' : 'assistant',
        'content': message.content,
      };
    }).toList();
  }
}