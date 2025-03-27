// lib/providers/conversation_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_model.dart';
import '../services/claude_service.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

class ConversationProvider with ChangeNotifier {
  final ClaudeService _claudeService;
  final StorageService _storageService;
  final _uuid = Uuid();

  // Current conversation state
  Conversation? _currentConversation;
  bool _isLoading = false;
  String? _error;

  // Message being processed
  bool _isProcessingMessage = false;
  String _processingStatus = '';

  // Getters
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProcessingMessage => _isProcessingMessage;
  String get processingStatus => _processingStatus;

  // Constructor
  ConversationProvider({
    required ClaudeService claudeService,
    required StorageService storageService,
  }) :
        _claudeService = claudeService,
        _storageService = storageService;

  // Initialize with an existing conversation
  Future<void> loadConversation(String conversationId) async {
    _setLoading(true);

    try {
      final conversation = await _storageService.getConversationById(conversationId);

      if (conversation != null) {
        _currentConversation = conversation;
        Logger.debug('Loaded conversation: ${conversation.id}');
      } else {
        _error = 'Conversation not found';
        Logger.error('Failed to load conversation cp1: $conversationId');
      }
    } catch (e) {
      _error = 'Failed to load conversation cp2: $e';
      Logger.error(_error!);
    } finally {
      _setLoading(false);
    }
  }

  // Create a new free-form conversation
  void createNewConversation({String? title}) {
    final now = DateTime.now();
    final conversationId = _uuid.v4();

    _currentConversation = Conversation(
      id: conversationId,
      title: title ?? 'Conversation ${now.toString().substring(0, 16)}',
      createdAt: now,
      updatedAt: now,
      messages: [],
      type: ConversationType.freeForm,
    );

    Logger.debug('Created new conversation: ${_currentConversation!.id}');

    // 새 대화를 즉시 저장
    _saveCurrentConversation();

    notifyListeners();
  }

  // Create a new scenario-based conversation
  void createScenarioConversation({
    required String scenarioId,
    required String title,
  }) {
    final now = DateTime.now();
    final conversationId = _uuid.v4();

    _currentConversation = Conversation(
      id: conversationId,
      title: title,
      createdAt: now,
      updatedAt: now,
      messages: [],
      type: ConversationType.scenario,
      scenarioId: scenarioId,
    );

    Logger.debug('Created new scenario conversation: ${_currentConversation!.id}');

    // 새 대화를 즉시 저장
    _saveCurrentConversation();

    notifyListeners();
  }

  // Create a new QA-based conversation
  void createQAConversation({
    required String qaSetId,
    required String title,
  }) {
    final now = DateTime.now();
    final conversationId = _uuid.v4();

    _currentConversation = Conversation(
      id: conversationId,
      title: title,
      createdAt: now,
      updatedAt: now,
      messages: [],
      type: ConversationType.qa,
      qaSetId: qaSetId,
    );

    Logger.debug('Created new QA conversation: ${_currentConversation!.id}');

    // 새 대화를 즉시 저장
    _saveCurrentConversation();

    notifyListeners();
  }

  // Add a user message to the conversation
  void addUserMessage(String content) {
    if (_currentConversation == null) {
      _error = 'No active conversation';
      Logger.error(_error!);
      notifyListeners();
      return;
    }

    final message = Message(
      id: _uuid.v4(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [..._currentConversation!.messages, message];

    _currentConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    // Save after adding user message
    _saveCurrentConversation();

    notifyListeners();
  }

  // Add an AI message to the conversation
  void addAIMessage(String content, {String? correctedContent, String? pronunciationFeedback}) {
    if (_currentConversation == null) {
      _error = 'No active conversation';
      Logger.error(_error!);
      notifyListeners();
      return;
    }

    final message = Message(
      id: _uuid.v4(),
      content: content,
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      correctedContent: correctedContent,
      pronunciationFeedback: pronunciationFeedback,
    );

    final updatedMessages = [..._currentConversation!.messages, message];

    _currentConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    // Save after adding AI message
    _saveCurrentConversation();

    notifyListeners();
  }

  // Process a user message and get AI response
  Future<void> processUserMessage(String userMessage, String systemPrompt) async {
    // First add the user message
    addUserMessage(userMessage);

    _isProcessingMessage = true;
    _processingStatus = 'Sending to Claude AI...';
    notifyListeners();

    try {
      if (_currentConversation == null) {
        throw Exception('No active conversation');
      }

      final response = await _claudeService.processConversation(
        messages: _currentConversation!.messages,
        systemPrompt: systemPrompt,
        enableSpeechImprovement: true,
      );

      // Extract any corrections or feedback (implementation depends on Claude's response format)
      final processedResponse = _processAIResponse(response);

      addAIMessage(
        processedResponse['message'] ?? '',
        correctedContent: processedResponse['correction'],
        pronunciationFeedback: processedResponse['pronunciation'],
      );

    } catch (e) {
      _error = 'Failed to process message: $e';
      Logger.error(_error!);
    } finally {
      _isProcessingMessage = false;
      _processingStatus = '';
      notifyListeners();
    }
  }

  // Helper method to process AI response and extract corrections/feedback
  Map<String, String?> _processAIResponse(String response) {
    // Initialize result map
    final result = {
      'message': response,
      'correction': null,
      'pronunciation': null,
    };

    // Extract correction if present
    final correctionRegex = RegExp(r'\[correct: (.*?)\]');
    final correctionMatch = correctionRegex.firstMatch(response);

    if (correctionMatch != null) {
      result['correction'] = correctionMatch.group(1);
      // Remove the correction markup from the message
      result['message'] = response.replaceAll(correctionRegex, '');
    }

    // Extract pronunciation feedback if present
    final pronunciationRegex = RegExp(r'\[pronunciation: (.*?)\]');
    final pronunciationMatch = pronunciationRegex.firstMatch(response);

    if (pronunciationMatch != null) {
      result['pronunciation'] = pronunciationMatch.group(1);
      // Remove the pronunciation markup from the message
      result['message'] = (result['message'] as String).replaceAll(pronunciationRegex, '');
    }

    return result;
  }

  // Get all conversations
  Future<List<Conversation>> getAllConversations() async {
    try {
      return await _storageService.getConversations();
    } catch (e) {
      _error = 'Failed to get conversations: $e';
      Logger.error(_error!);
      return [];
    }
  }

  // Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final success = await _storageService.deleteConversation(conversationId);

      if (success && _currentConversation?.id == conversationId) {
        _currentConversation = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Failed to delete conversation: $e';
      Logger.error(_error!);
      return false;
    }
  }

  // Save current conversation
  Future<void> _saveCurrentConversation() async {
    if (_currentConversation == null) return;

    try {
      await _storageService.saveConversation(_currentConversation!);
      Logger.debug('Saved conversation: ${_currentConversation!.id}');
    } catch (e) {
      _error = 'Failed to save conversation: $e';
      Logger.error(_error!);
    }
  }

  // Update conversation title
  Future<void> updateConversationTitle(String newTitle) async {
    if (_currentConversation == null) {
      _error = 'No active conversation';
      Logger.error(_error!);
      notifyListeners();
      return;
    }

    _currentConversation = _currentConversation!.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );

    await _saveCurrentConversation();
    notifyListeners();
  }

  // Clear current conversation from memory (doesn't delete from storage)
  void clearCurrentConversation() {
    _currentConversation = null;
    notifyListeners();
  }

  // Handle loading state
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}