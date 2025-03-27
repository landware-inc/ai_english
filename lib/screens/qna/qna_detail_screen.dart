// lib/screens/qna/qna_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/qa_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../models/question_answer_model.dart';
import '../../routes.dart';
import '../../widgets/loading_indicator.dart';
import 'dart:convert';

class QnADetailScreen extends StatefulWidget {
  final String qaSetId;

  const QnADetailScreen({
    Key? key,
    required this.qaSetId,
  }) : super(key: key);

  @override
  State<QnADetailScreen> createState() => _QnADetailScreenState();
}

class _QnADetailScreenState extends State<QnADetailScreen> {
  QASet? _qaSet;
  List<QASessionProgress> _pastSessions = [];
  bool _isLoading = true;
  bool _isLoadingSessions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQASet();
    _loadPastSessions();
  }

  Future<void> _loadQASet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final qaProvider = Provider.of<QAProvider>(context, listen: false);
      final jsonContent =
          await qaProvider.storageService.readQADataset(widget.qaSetId);

      if (jsonContent != null) {
        final qaData = jsonDecode(jsonContent);
        final qaSet = QASet.fromJson(qaData);

        setState(() {
          _qaSet = qaSet;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'QA set not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load QA set: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPastSessions() async {
    setState(() {
      _isLoadingSessions = true;
    });

    try {
      final qaProvider = Provider.of<QAProvider>(context, listen: false);
      final allSessions = await qaProvider.getAllSessions();

// Filter sessions for this QA set
      final filteredSessions = allSessions
          .where((session) => session.qaSetId == widget.qaSetId)
          .toList();

// Sort by start time, most recent first
      filteredSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      setState(() {
        _pastSessions = filteredSessions;
        _isLoadingSessions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSessions = false;
      });

      print('Error loading past sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_qaSet?.title ?? 'Q&A Set Details'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading question set...')
          : _buildBody(),
      bottomNavigationBar: _qaSet != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
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
              onPressed: _loadQASet,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_qaSet == null) {
      return const Center(
        child: Text('Question set not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// QA set header card
          _buildQASetHeader(),

          const SizedBox(height: 24),

// Questions preview
          _buildQuestionsPreview(),

          const SizedBox(height: 24),

// Past sessions
          _buildPastSessions(),
        ],
      ),
    );
  }

  Widget _buildQASetHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(_qaSet!.category),
                    color: Colors.green.shade800,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _qaSet!.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_qaSet!.questions.length} questions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_qaSet!.description),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDifficultyIndicator(_qaSet!.difficulty),
                const SizedBox(width: 8),
                if (_qaSet!.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsPreview() {
    final questions = _qaSet!.questions;

    // Show only first 5 questions as preview
    final previewQuestions = questions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Questions Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'Showing ${previewQuestions.length} of ${questions.length}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...previewQuestions.map((question) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${question.id}: ${question.question}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sample answer: ${question.possibleAnswers.first}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPastSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Practice Sessions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingSessions)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_pastSessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No practice sessions yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Start a new session to begin practicing',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...List.generate(_pastSessions.length > 3 ? 3 : _pastSessions.length,
              (index) {
            final session = _pastSessions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  if (session.isCompleted) {
                    // View session summary
                  } else {
                    // Continue session
                    _continueSession(session.sessionId, session.conversationId);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            session.isCompleted
                                ? Icons.check_circle
                                : Icons.timelapse,
                            color: session.isCompleted
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              session.isCompleted
                                  ? 'Completed Session'
                                  : 'In Progress',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(session.startTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: session.progressPercentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          session.isCompleted ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress: ${(session.progressPercentage * 100).toInt()}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (session.isCompleted)
                            Text(
                              'Score: ${session.scorePercentage.toInt()}%',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        if (_pastSessions.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                // Show all past sessions
              },
              child: const Text('View All Sessions'),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _startNewSession,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Start New Practice Session',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(dynamic difficulty) {
    Color color;
    String text;

    if (difficulty is int) {
      // 기존 숫자 기반 로직
      switch (difficulty) {
        case 1:
          color = Colors.green;
          text = 'Beginner';
          break;
        case 2:
          color = Colors.lightGreen;
          text = 'Elementary';
          break;
        case 3:
          color = Colors.orange;
          text = 'Intermediate';
          break;
        case 4:
          color = Colors.deepOrange;
          text = 'Advanced';
          break;
        case 5:
          color = Colors.red;
          text = 'Expert';
          break;
        default:
          color = Colors.grey;
          text = 'Unknown';
      }
    } else if (difficulty is String) {
      // 문자열 기반 로직 추가
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          color = Colors.green;
          text = 'Beginner';
          break;
        case 'elementary':
          color = Colors.lightGreen;
          text = 'Elementary';
          break;
        case 'intermediate':
        case 'medium':
          color = Colors.orange;
          text = 'Intermediate';
          break;
        case 'advanced':
          color = Colors.deepOrange;
          text = 'Advanced';
          break;
        case 'expert':
        case 'hard':
          color = Colors.red;
          text = 'Expert';
          break;
        default:
          color = Colors.grey;
          text = difficulty;  // 입력된 문자열 그대로 사용
      }
    } else {
      // 다른 타입은 기본값 사용
      color = Colors.grey;
      text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'citizenship':
        return Icons.gavel;
      case 'language':
        return Icons.language;
      case 'culture':
        return Icons.local_activity;
      case 'history':
        return Icons.history_edu;
      case 'science':
        return Icons.science;
      default:
        return Icons.question_answer;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _startNewSession() async {
    try {
      final qaProvider = Provider.of<QAProvider>(context, listen: false);
      final conversationProvider =
          Provider.of<ConversationProvider>(context, listen: false);

      // Load the QA set
      await qaProvider.loadQASet(widget.qaSetId);

      // Create a conversation for this session
      conversationProvider.createQAConversation(
        qaSetId: widget.qaSetId,
        title: _qaSet?.title ?? 'Q&A Practice',
      );

      final conversationId = conversationProvider.currentConversation!.id;

      // Start a new QA session
      final sessionId = await qaProvider.startNewSession(conversationId);

      if (sessionId != null && mounted) {
        // Navigate to the practice screen
        Navigator.of(context).pushNamed(
          AppRoutes.qnaPractice,
          arguments: {
            'sessionId': sessionId,
            'conversationId': conversationId,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting session: $e')),
      );
    }
  }

  Future<void> _continueSession(String sessionId, String conversationId) async {
    try {
      // Navigate to the practice screen
      Navigator.of(context).pushNamed(
        AppRoutes.qnaPractice,
        arguments: {
          'sessionId': sessionId,
          'conversationId': conversationId,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error continuing session: $e')),
      );
    }
  }
}
