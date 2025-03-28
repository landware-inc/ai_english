// lib/screens/scenario/scenario_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../models/scenario_model.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/scenario_provider.dart';
import '../../services/speech_service.dart';
import '../../widgets/conversation_bubble.dart';
import '../../widgets/voice_only_speech_input.dart';
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
  bool _shouldAutoActivateMic = false;
  String? _error;

  // Keep track of the last spoken message ID to avoid repeating
  String? _lastSpokenMessageId;

  // Flag to track if we've completed initial conversation loading
  bool _conversationInitiallyLoaded = false;

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

      setState(() {
        _isInitialized = true;
      });

      // Always initiate conversation with AI message first, either
      // by using existing one or creating a new one
      if (conversationProvider.currentConversation?.messages.isEmpty ?? true) {
        // New conversation - send initial message
        debugPrint("Starting new scenario conversation");
        await _sendInitialMessage();
      } else {
        // Existing conversation - just speak last AI message
        debugPrint("Resuming existing scenario conversation");
        // Add a short delay to ensure the UI is updated before speaking
        Future.delayed(const Duration(milliseconds: 500), () {
          _speakLastAIMessage(autoActivateMic: true);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize conversation: $e';
      });
    }
  }

  Future<void> _sendInitialMessage() async {
    final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    final session = scenarioProvider.currentSession;

    if (session == null) {
      debugPrint("Error: No active scenario session found");
      return;
    }

    // Generate system prompt
    final systemPrompt = scenarioProvider.generateSystemPrompt();

    // Create a starting message based on the scenario context
    final startingMessage = _generateStartingPrompt(session);
    debugPrint("Starting scenario with prompt: $startingMessage");

    // Process the starting message to get the AI's opening line
    await conversationProvider.processUserMessage(startingMessage, systemPrompt);

    // Let UI update before we return
    await Future.delayed(const Duration(milliseconds: 500));

    // Speak the AI's opening message
    _speakLastAIMessage(autoActivateMic: true);
  }

  // Generate a starting prompt to help Claude understand how to begin the conversation
  String _generateStartingPrompt(ScenarioSession session) {
    final role = session.selectedRole;
    final scenario = session.scenario.name;
    final keywords = session.selectedKeywords.join(", ");

    return "Please start the scenario conversation as if you're talking to a '$role' in a '$scenario' scenario. "
        "Focus on these keywords: $keywords. Begin the conversation naturally as if we just met in this situation. "
        "Keep your first message brief and conversational. This message won't be shown to the user.";
  }

  void _speakLastAIMessage({bool autoActivateMic = false}) {
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    final speechService = Provider.of<SpeechService>(context, listen: false);

    if (conversationProvider.currentConversation == null ||
        conversationProvider.currentConversation!.messages.isEmpty) {
      return;
    }

    // Find the last AI message
    final messages = conversationProvider.currentConversation!.messages;
    Message? lastAIMessage;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.ai) {
        lastAIMessage = messages[i];
        break;
      }
    }

    if (lastAIMessage != null) {
      // First stop any ongoing TTS
      speechService.stopSpeaking();

      // Log the message content for debugging
      debugPrint('Speaking message: ${lastAIMessage.content}');

      setState(() {
        _shouldAutoActivateMic = autoActivateMic;
      });

      // Read the message and auto-activate mic when done
      speechService.speak(lastAIMessage.content, onComplete: () {
        debugPrint('TTS completed, should activate mic: $autoActivateMic');
        if (autoActivateMic && mounted) {
          setState(() {
            _shouldAutoActivateMic = true;
          });
        }
      });
    } else {
      debugPrint('No AI message found to speak');
    }
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
            icon: const Icon(Icons.volume_up),
            onPressed: () => _speakLastAIMessage(autoActivateMic: true),
            tooltip: 'Speak last message',
          ),
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

          // Voice-only input area
          if (_isInitialized)
            Consumer<ConversationProvider>(
              builder: (context, conversationProvider, child) {
                // System prompt from scenario
                final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);
                final systemPrompt = scenarioProvider.generateSystemPrompt();

                return VoiceOnlySpeechInput(
                  onSendMessage: (message) async {
                    // Reset the auto-activate flag when the user sends a message
                    setState(() {
                      _shouldAutoActivateMic = false;
                    });

                    // Process the message
                    await conversationProvider.processUserMessage(message, systemPrompt);

                    // Scroll to show new message
                    _scrollToBottom();
                  },
                  isProcessing: conversationProvider.isProcessingMessage,
                  processingStatus: conversationProvider.processingStatus,
                  autoActivate: _shouldAutoActivateMic,
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

        // Add a listener to automatically speak new AI messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // This will run after the build is complete
          // We'll check if the last message is from AI and if it's new
          if (messages.isNotEmpty &&
              messages.last.role == MessageRole.ai &&
              messages.last.id != _lastSpokenMessageId) {
            _lastSpokenMessageId = messages.last.id;

            // Don't auto-speak initial messages when first loading an existing conversation
            // (to avoid unexpected speech when navigating to the screen)
            // But do speak new messages that arrive during the conversation
            if (_conversationInitiallyLoaded) {
              // Auto-speak the new AI message with mic activation
              _speakLastAIMessage(autoActivateMic: true);
            } else {
              // Mark that we've now loaded the conversation initially
              _conversationInitiallyLoaded = true;
            }
          }
        });

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

              const SizedBox(height: 16),

              // Add voice mode instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Voice Mode Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• The AI will begin the conversation for your scenario'),
                    Text('• Tap the microphone to speak your response'),
                    Text('• The microphone will activate automatically after AI responses'),
                    Text('• Tap the speaker icon in the app bar to repeat the last message'),
                  ],
                ),
              ),
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