// lib/screens/qna/qna_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/qa_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../routes.dart';
import '../../widgets/loading_indicator.dart';
import 'dart:convert';

class QnAListScreen extends StatefulWidget {
  const QnAListScreen({Key? key}) : super(key: key);

  @override
  State<QnAListScreen> createState() => _QnAListScreenState();
}

class _QnAListScreenState extends State<QnAListScreen> {
  List<Map<String, dynamic>> _qaSets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQASets();
  }

  Future<void> _loadQASets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final qaProvider = Provider.of<QAProvider>(context, listen: false);
      final qaSetNames = await qaProvider.getAllQASets();

      final loadedSets = <Map<String, dynamic>>[];

      for (final name in qaSetNames) {
        final jsonContent = await qaProvider.storageService.readQADataset(name);
        if (jsonContent != null) {
          try {
            final qaData = jsonDecode(jsonContent);
            loadedSets.add({
              'id': qaData['id'],
              'title': qaData['title'],
              'description': qaData['description'],
              'category': qaData['category'],
              'difficulty': qaData['difficulty'],
              'questionsCount': (qaData['questions'] as List).length,
              'isPremium': qaData['isPremium'] ?? false,
            });
          } catch (e) {
            print('Error parsing QA set $name: $e');
          }
        }
      }

      setState(() {
        _qaSets = loadedSets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load QA sets: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Q&A Practice'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading question sets...')
          : _buildBody(),
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
              onPressed: _loadQASets,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_qaSets.isEmpty) {
      return const Center(
        child: Text('No question sets available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _qaSets.length,
      itemBuilder: (context, index) {
        final qaSet = _qaSets[index];
        return _buildQASetCard(qaSet);
      },
    );
  }

  Widget _buildQASetCard(Map<String, dynamic> qaSet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.qnaDetail,
            arguments: {'qaSetId': qaSet['id']},
          );
        },
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
                      _getCategoryIcon(qaSet['category']),
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
                          qaSet['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${qaSet['questionsCount']} questions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (qaSet['isPremium'])
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
              const SizedBox(height: 16),
              Text(qaSet['description']),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDifficultyIndicator(qaSet['difficulty']),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // View past sessions
                    },
                    child: const Text('Past Sessions'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _startNewSession(qaSet['id']);
                    },
                    child: const Text('Start Practice'),
                  ),
                ],
              ),
            ],
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

  Future<void> _startNewSession(String qaSetId) async {
    try {
      final qaProvider = Provider.of<QAProvider>(context, listen: false);
      final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);

      // Load the QA set
      await qaProvider.loadQASet(qaSetId);

      // Create a conversation for this session
      conversationProvider.createQAConversation(
        qaSetId: qaSetId,
        title: qaProvider.currentQASet?.title ?? 'Q&A Practice',
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
}