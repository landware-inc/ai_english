// lib/providers/qa_provider.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/question_answer_model.dart';
import '../models/conversation_model.dart';
import '../services/claude_service.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

class QAProvider with ChangeNotifier {
  final ClaudeService _claudeService;
  final StorageService storageService;
  final _uuid = Uuid();
  final Random _random = Random();

  // Current QA state
  QASet? _currentQASet;
  QASessionProgress? _currentSession;
  bool _isLoading = false;
  String? _error;

  // Processing state
  bool _isProcessing = false;
  String _processingStatus = '';

  // Current question
  int _currentQuestionIndex = 0;
  QuestionAnswer? _currentQuestion;

  // Randomized question order
  List<int> _questionOrder = [];

  // Getters
  QASet? get currentQASet => _currentQASet;
  QASessionProgress? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProcessing => _isProcessing;
  String get processingStatus => _processingStatus;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _currentQASet?.questions.length ?? 0;
  QuestionAnswer? get currentQuestion => _currentQuestion;
  bool get hasMoreQuestions => _currentQASet != null &&
      _currentQuestionIndex < _currentQASet!.questions.length - 1;

  // Constructor
  QAProvider({
    required ClaudeService claudeService,
    required StorageService storageService,
  }) :
        _claudeService = claudeService,
        storageService = storageService;

  // Load a QA set by ID or filename
  Future<void> loadQASet(String qaSetIdOrFile) async {
    _setLoading(true);

    try {
      // Try to load from a file first
      final qaSetJson = await storageService.readQADataset(qaSetIdOrFile);

      if (qaSetJson != null) {
        Logger.debug('Raw QA set JSON: ${qaSetJson.substring(0, min(200, qaSetJson.length))}...'); // 파일 내용의 일부를 로그로 출력

        try {
          final decodedJson = jsonDecode(qaSetJson);
          Logger.debug('Decoded JSON structure: ${decodedJson.runtimeType}');

          if (decodedJson is Map) {
            Logger.debug('JSON keys: ${decodedJson.keys.toList()}');
          }

          _currentQASet = QASet.fromJson(decodedJson);
          Logger.debug('Loaded QA set from file: ${_currentQASet!.title}, ${_currentQASet!.questions.length} questions');

          // Create a randomized order for questions
          _randomizeQuestionOrder();

        } catch (parseError) {
          Logger.error('JSON parsing error: $parseError');
          throw Exception('Failed to parse QA data: $parseError');
        }
      } else {
        // TODO: Load from API or bundled assets
        throw Exception('QA set not found: $qaSetIdOrFile');
      }

      // Reset session state
      _currentQuestionIndex = 0;
      _updateCurrentQuestion();

    } catch (e) {
      _error = 'Failed to load QA set: $e';
      Logger.error(_error!);
    } finally {
      _setLoading(false);
    }
  }

  // Randomize the order of questions
  void _randomizeQuestionOrder() {
    if (_currentQASet == null) return;

    // Create a list of indices from 0 to questions.length-1
    _questionOrder = List.generate(_currentQASet!.questions.length, (index) => index);

    // Shuffle the list
    _questionOrder.shuffle(_random);

    Logger.debug('Randomized question order: $_questionOrder');
  }

  // Start a new QA session
  Future<String?> startNewSession(String conversationId) async {
    if (_currentQASet == null) {
      _error = 'No QA set loaded';
      Logger.error(_error!);
      notifyListeners();
      return null;
    }

    try {
      final sessionId = _uuid.v4();

      _currentSession = QASessionProgress(
        qaSetId: _currentQASet!.id,
        sessionId: sessionId,
        startTime: DateTime.now(),
        currentQuestionIndex: 0,
        totalQuestions: _currentQASet!.questions.length,
        responses: [],
        conversationId: conversationId,
      );

      // Save the initial session
      await storageService.saveQASession(_currentSession!);

      _currentQuestionIndex = 0;
      _updateCurrentQuestion();

      Logger.debug('Started new QA session: $sessionId');
      notifyListeners();

      return sessionId;
    } catch (e) {
      _error = 'Failed to start new session: $e';
      Logger.error(_error!);
      notifyListeners();
      return null;
    }
  }

  // Load an existing session
  Future<void> loadSession(String sessionId) async {
    _setLoading(true);

    try {
      final session = await storageService.getQASessionById(sessionId);

      if (session != null) {
        _currentSession = session;

        // Load the associated QA set
        await loadQASet(session.qaSetId);

        // Set the current question index
        _currentQuestionIndex = session.currentQuestionIndex;
        _updateCurrentQuestion();

        Logger.debug('Loaded QA session: $sessionId');
      } else {
        _error = 'Session not found';
        Logger.error('Failed to load session: $sessionId');
      }
    } catch (e) {
      _error = 'Failed to load session: $e';
      Logger.error(_error!);
    } finally {
      _setLoading(false);
    }
  }

  // Process a user's answer to the current question
  Future<Map<String, dynamic>> processUserAnswer(String userAnswer) async {
    if (_currentQuestion == null || _currentSession == null) {
      _error = 'No active question or session';
      Logger.error(_error!);
      notifyListeners();
      return {
        'success': false,
        'error': _error,
      };
    }

    _isProcessing = true;
    _processingStatus = 'Evaluating your answer...';
    notifyListeners();

    try {
      // Evaluate the answer using Claude AI
      final evaluation = await _claudeService.evaluateQAResponse(
        question: _currentQuestion!.question,
        userAnswer: userAnswer,
        correctAnswers: _currentQuestion!.possibleAnswers,
        keywords: _currentQuestion!.keywords,
      );

      // Create a response record
      final response = QAResponse(
        questionId: _currentQuestion!.id,
        userAnswer: userAnswer,
        wasCorrect: evaluation['isCorrect'] ?? false,
        aiEvaluation: evaluation['feedback'],
        suggestedCorrectAnswers: List<String>.from(evaluation['suggestedAnswers'] ?? []),
        answeredAt: DateTime.now(),
      );

      // Update the session with this response
      final updatedResponses = [..._currentSession!.responses, response];
      _currentSession = QASessionProgress(
        qaSetId: _currentSession!.qaSetId,
        sessionId: _currentSession!.sessionId,
        startTime: _currentSession!.startTime,
        currentQuestionIndex: _currentQuestionIndex,
        totalQuestions: _currentSession!.totalQuestions,
        responses: updatedResponses,
        conversationId: _currentSession!.conversationId,
      );

      // Save the updated session
      await storageService.saveQASession(_currentSession!);

      Logger.debug('Processed answer for question ${_currentQuestion!.id}');

      return {
        'success': true,
        'isCorrect': response.wasCorrect,
        'feedback': response.aiEvaluation,
        'suggestedAnswers': response.suggestedCorrectAnswers,
      };

    } catch (e) {
      _error = 'Failed to process answer: $e';
      Logger.error(_error!);
      return {
        'success': false,
        'error': _error,
      };
    } finally {
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
    }
  }

  // Move to the next question
  bool moveToNextQuestion() {
    if (_currentQASet == null || !hasMoreQuestions) {
      return false;
    }

    _currentQuestionIndex++;
    _updateCurrentQuestion();

    // Update session if available
    if (_currentSession != null) {
      _currentSession = QASessionProgress(
        qaSetId: _currentSession!.qaSetId,
        sessionId: _currentSession!.sessionId,
        startTime: _currentSession!.startTime,
        currentQuestionIndex: _currentQuestionIndex,
        totalQuestions: _currentSession!.totalQuestions,
        responses: _currentSession!.responses,
        conversationId: _currentSession!.conversationId,
      );

      // Save the updated session
      storageService.saveQASession(_currentSession!).then((_) {
        Logger.debug('Updated session with new question index: $_currentQuestionIndex');
      }).catchError((e) {
        Logger.error('Failed to save session: $e');
      });
    }

    notifyListeners();
    return true;
  }

  // End the current session
  Future<void> endSession({bool completed = true}) async {
    if (_currentSession == null) return;

    try {
      // Mark session as completed
      _currentSession = QASessionProgress(
        qaSetId: _currentSession!.qaSetId,
        sessionId: _currentSession!.sessionId,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        currentQuestionIndex: _currentQuestionIndex,
        totalQuestions: _currentSession!.totalQuestions,
        responses: _currentSession!.responses,
        conversationId: _currentSession!.conversationId,
      );

      // Save the completed session
      await storageService.saveQASession(_currentSession!);

      Logger.debug('Ended QA session: ${_currentSession!.sessionId}');
    } catch (e) {
      _error = 'Failed to end session: $e';
      Logger.error(_error!);
    } finally {
      notifyListeners();
    }
  }

  // Get all QA sets
  Future<List<String>> getAllQASets() async {
    try {
      return await storageService.listQADatasets();
    } catch (e) {
      _error = 'Failed to get QA sets: $e';
      Logger.error(_error!);
      return [];
    }
  }

  // Get all sessions
  Future<List<QASessionProgress>> getAllSessions() async {
    try {
      return await storageService.getQASessions();
    } catch (e) {
      _error = 'Failed to get sessions: $e';
      Logger.error(_error!);
      return [];
    }
  }

  // Delete a session
  Future<bool> deleteSession(String sessionId) async {
    try {
      final success = await storageService.deleteQASession(sessionId);

      if (success && _currentSession?.sessionId == sessionId) {
        _currentSession = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Failed to delete session: $e';
      Logger.error(_error!);
      return false;
    }
  }

  // Process US citizenship questions from the PDF
  Future<bool> processUSCitizenshipQuestions(String jsonContent) async {
    try {
      // Save the processed data to storage
      return await storageService.saveQADataset('us_citizenship_questions', jsonContent);
    } catch (e) {
      _error = 'Failed to process US citizenship questions: $e';
      Logger.error(_error!);
      return false;
    }
  }

  // Helper method to update the current question
  void _updateCurrentQuestion() {
    debugPrint('Updating current question: $_currentQuestionIndex of QAset[${_currentQASet?.questions.length}]');

    if (_currentQASet == null ||
        _currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _currentQASet!.questions.length) {
      _currentQuestion = null;
    } else {
      // Use the randomized order to get the actual question index
      final actualQuestionIndex = _questionOrder.isNotEmpty ?
      _questionOrder[_currentQuestionIndex] :
      _currentQuestionIndex;

      _currentQuestion = _currentQASet!.questions[actualQuestionIndex];
      Logger.debug('Showing question at randomized index $actualQuestionIndex: ${_currentQuestion!.question}');
    }
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