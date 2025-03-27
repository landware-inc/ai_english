// lib/screens/scenario/scenario_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/scenario_provider.dart';
import '../../services/speech_service.dart';
import '../../widgets/conversation_bubble.dart';
import '../../widgets/speech_input.dart';
import '../../widgets/loading_indicator.dart';

class ScenarioChatScreen extends StatefulWidget {
  final String sessionId;
  final String conversationId;

  const ScenarioChatScreen({
    Key? key,
    required this.sessionId,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<ScenarioChatScreen> createState() => _ScenarioChatScreenState();
}

class _ScenarioChatScreenState extends State<ScenarioChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    try {
      // Load the scenario session
      final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);
      await scenarioProvider.loadSession(widget.sessionId);

      // Load the conversation
      final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
      await conversationProvider.loadConversation(widget.conversationId);

      // Add initial AI message if conversation is empty
      if (conversationProvider.currentConversation?.messages.isEmpty ?? true) {
        _sendInitialMessage();
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize conversation: $e';
      });
    }
  }

  void _sendInitialMessage() {
    final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);

    // Generate system prompt
    final systemPrompt = scenarioProvider.generateSystemPrompt();

    // Process the empty message to get the AI's opening line
    conversationProvider.processUserMessage('', systemPrompt);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showScenarioInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Error message if any
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade800),
                textAlign: TextAlign.center,
              ),
            ),

          // Conversation messages area
          Expanded(
            child: _buildConversationArea(),
          ),

          // Input area
          if (_isInitialized)
            Consumer<ConversationProvider>(
              builder: (context, conversationProvider, child) {
                // System prompt from scenario
                final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);
                final systemPrompt = scenarioProvider.generateSystemPrompt();

                return SpeechInput(
                  onSendMessage: (message) {
                    conversationProvider.processUserMessage(message, systemPrompt);
                    _scrollToBottom();
                  },
                  isProcessing: conversationProvider.isProcessingMessage,
                  processingStatus: conversationProvider.processingStatus,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    if (!_isInitialized) {
      return const LoadingIndicator(message: 'Loading conversation...');
    }

    return Consumer<ConversationProvider>(
      builder: (context, conversationProvider, child) {
        if (conversationProvider.currentConversation == null) {
          return const Center(child: Text('Conversation not found'));
        }

        final messages = conversationProvider.currentConversation!.messages;

        if (messages.isEmpty) {
          return const Center(child: Text('No messages yet'));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            // Scroll to bottom when new messages are added
            if (index == messages.length - 1) {
              _scrollToBottom();
            }

            final message = messages[index];
            return ConversationBubble(
              message: message,
              onTapCorrection: () {
                // Show correction details
                if (message.correctedContent != null || message.pronunciationFeedback != null) {
                  _showCorrectionDetails(message);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showScenarioInfo() {
    final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);
    final session = scenarioProvider.currentSession;

    if (session == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.scenario.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your role: ${session.selectedRole}'),
              const SizedBox(height: 8),

              if (session.selectedKeywords.isNotEmpty) ...[
                const Text(
                  'Keywords:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: session.selectedKeywords.map((keyword) {
                    return Chip(label: Text(keyword));
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],

              if (session.practicePhrasesAdded.isNotEmpty) ...[
                const Text(
                  'Practice phrases:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...session.practicePhrasesAdded.map((phrase) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $phrase'),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCorrectionDetails(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (message.correctedContent != null) ...[
              const Text(
                'Suggested correction:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(message.correctedContent!),
              const SizedBox(height: 16),
            ],

            if (message.pronunciationFeedback != null) ...[
              const Text(
                'Pronunciation tip:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(message.pronunciationFeedback!),
            ],

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}