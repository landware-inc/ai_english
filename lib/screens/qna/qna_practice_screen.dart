// lib/screens/qna/qna_practice_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question_answer_model.dart';
import '../../providers/qa_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../services/speech_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/voice_only_speech_input.dart'; // Import the new widget
import '../../routes.dart';

class QnAPracticeScreen extends StatefulWidget {
  final String sessionId;
  final String conversationId;

  const QnAPracticeScreen({
    Key? key,
    required this.sessionId,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<QnAPracticeScreen> createState() => _QnAPracticeScreenState();
}

class _QnAPracticeScreenState extends State<QnAPracticeScreen> {
  bool _isInitialized = false;
  bool _isProcessingAnswer = false;
  bool _isShowingFeedback = false;
  bool _shouldAutoActivateMic = false;
  String? _error;
  Map<String, dynamic>? _currentFeedback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  Future<void> _initializeSession() async {
    try {
      // Load the QA session
      final qaProvider = Provider.of<QAProvider>(context, listen: false);
      await qaProvider.loadSession(widget.sessionId);

      // Load the conversation
      final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
      await conversationProvider.loadConversation(widget.conversationId);

      setState(() {
        _isInitialized = true;
      });

      // Speak the current question and auto-activate microphone after it finishes
      _speakCurrentQuestion(autoActivateMic: true);
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize session: $e';
      });
    }
  }

  void _speakCurrentQuestion({bool autoActivateMic = false}) {
    final qaProvider = Provider.of<QAProvider>(context, listen: false);
    final speechService = Provider.of<SpeechService>(context, listen: false);

    if (qaProvider.currentQuestion != null) {
      debugPrint('Speaking question: ${qaProvider.currentQuestion?.question}');

      setState(() {
        _shouldAutoActivateMic = autoActivateMic;
      });

      // Use the onComplete callback to auto-activate microphone
      speechService.speak(qaProvider.currentQuestion!.question, onComplete: () {
        if (autoActivateMic && mounted) {
          setState(() {
            _shouldAutoActivateMic = true;
          });
        }
      });
    } else {
      debugPrint('No question to speak');
    }
  }

  Future<void> _processAnswer(String answer) async {
    if (_isProcessingAnswer || _isShowingFeedback) return;

    setState(() {
      _isProcessingAnswer = true;
      _currentFeedback = null;
    });

    try {
      final qaProvider = Provider.of<QAProvider>(context, listen: false);
      final result = await qaProvider.processUserAnswer(answer);

      // Add to conversation
      final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);

      // Add user's answer
      conversationProvider.addUserMessage(answer);

      if (result['success']) {
        setState(() {
          _isShowingFeedback = true;
          _currentFeedback = result;
        });

        // Add AI's feedback
        String aiMessage = result['isCorrect']
            ? "That's correct! ${result['feedback']}"
            : "Not quite. ${result['feedback']}";

        if (!result['isCorrect'] && result['suggestedAnswers'] != null) {
          aiMessage += "\n\nCorrect answers include: ${result['suggestedAnswers'].join(' or ')}";
        }

        conversationProvider.addAIMessage(aiMessage);

        // Speak the feedback
        final speechService = Provider.of<SpeechService>(context, listen: false);
        speechService.speak(aiMessage);
      } else {
        setState(() {
          _error = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error processing answer: $e';
      });
    } finally {
      setState(() {
        _isProcessingAnswer = false;
      });
    }
  }

  void _moveToNextQuestion() {
    final qaProvider = Provider.of<QAProvider>(context, listen: false);
    final speechService = Provider.of<SpeechService>(context, listen: false);

    // Stop any ongoing speech
    speechService.stopSpeaking();

    if (qaProvider.hasMoreQuestions) {
      final success = qaProvider.moveToNextQuestion();

      if (success) {
        setState(() {
          _isShowingFeedback = false;
          _currentFeedback = null;
        });

        // Speak the new question and auto-activate microphone after
        _speakCurrentQuestion(autoActivateMic: true);
      }
    } else {
      // End of questions, complete the session
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    final qaProvider = Provider.of<QAProvider>(context, listen: false);
    await qaProvider.endSession(completed: true);

    if (!mounted) return;

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Practice Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'You have completed this practice session!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${qaProvider.currentSession?.scorePercentage.toInt()}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Correct answers: ${qaProvider.currentSession?.correctAnswers} / ${qaProvider.currentSession?.responses.length}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Return to QA set detail
              Navigator.of(context).popUntil(
                      (route) => route.settings.name == AppRoutes.qnaDetail
              );
            },
            child: const Text('Back to Question Set'),
          ),
          ElevatedButton(
            onPressed: () {
              // View conversation history
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.historyDetail,
                arguments: {'conversationId': widget.conversationId},
              );
            },
            child: const Text('View Conversation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized) {
      return const LoadingIndicator(message: 'Loading practice session...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeSession,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Question area
        Expanded(
          child: _buildQuestionArea(),
        ),

        // Voice input area (using our new widget)
        if (!_isShowingFeedback)
          Consumer<QAProvider>(
            builder: (context, qaProvider, child) {
              return VoiceOnlySpeechInput(
                onSendMessage: _processAnswer,
                isProcessing: _isProcessingAnswer,
                processingStatus: 'Evaluating your answer...',
                autoActivate: _shouldAutoActivateMic,
              );
            },
          ),

        // Feedback area
        if (_isShowingFeedback)
          _buildFeedbackArea(),
      ],
    );
  }

  Widget _buildQuestionArea() {
    return Consumer<QAProvider>(
      builder: (context, qaProvider, child) {
        final question = qaProvider.currentQuestion;
        final session = qaProvider.currentSession;

        if (question == null || session == null) {
          return const Center(child: Text('No question available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: session.progressPercentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${qaProvider.currentQuestionIndex + 1} of ${session.totalQuestions}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (session.responses.isNotEmpty)
                      Text(
                        'Score: ${session.scorePercentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Question card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (question.isMarkedWithAsterisk)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '65+ Years',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                '${qaProvider.currentQuestionIndex + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              question.question,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (question.hint != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hint: ${question.hint}',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Instructions - simpler now with voice-only mode
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Voice Mode Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the microphone button to speak your answer. The microphone will activate automatically after each question.',
                    ),
                    const SizedBox(height: 8),
                    if (question.keywords.isNotEmpty)
                      Text(
                        'Your answer should include concepts like: ${question.keywords.join(', ')}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackArea() {
    if (_currentFeedback == null) return const SizedBox.shrink();

    final isCorrect = _currentFeedback!['isCorrect'] as bool;
    final feedback = _currentFeedback!['feedback'] as String;
    final suggestedAnswers = _currentFeedback!['suggestedAnswers'] as List<dynamic>;

    return Container(
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.info_outline,
                  color: isCorrect ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? 'Correct!' : 'Not quite right',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(feedback),
            if (!isCorrect && suggestedAnswers.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Correct answers include:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...suggestedAnswers.map((answer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(answer.toString())),
                    ],
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _moveToNextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? Colors.green : Colors.orange,
                ),
                child: Text(
                  Provider.of<QAProvider>(context, listen: false).hasMoreQuestions
                      ? 'Next Question'
                      : 'Complete Practice',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Mode Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. Listen to the question being read'),
            SizedBox(height: 8),
            Text('2. The microphone will automatically activate when the question finishes'),
            SizedBox(height: 8),
            Text('3. Speak your answer clearly'),
            SizedBox(height: 8),
            Text('4. Tap the microphone again if you need to stop or restart'),
            SizedBox(height: 8),
            Text('5. Listen to the feedback and tap "Next Question" to continue'),
            SizedBox(height: 16),
            Text(
              'The microphone icon will turn red when it\'s listening to your answer.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}