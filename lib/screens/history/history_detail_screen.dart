// lib/screens/history/history_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/scenario_provider.dart';
import '../../providers/qa_provider.dart';
import '../../models/conversation_model.dart';
import '../../widgets/conversation_bubble.dart';
import '../../widgets/loading_indicator.dart';
import '../../routes.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String conversationId;

  const HistoryDetailScreen({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
      await conversationProvider.loadConversation(widget.conversationId);

      setState(() {
        _isLoading = false;
      });

      // Scroll to bottom after loading
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = 'Failed to load conversation hd1: $e';
        _isLoading = false;
      });
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
        title: Consumer<ConversationProvider>(
          builder: (context, provider, child) {
            return Text(provider.currentConversation?.title ?? 'Conversation');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showConversationInfo,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'continue',
                child: Text('Continue Conversation'),
              ),
              const PopupMenuItem<String>(
                value: 'rename',
                child: Text('Rename'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading conversation...')
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
              onPressed: _loadConversation,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Consumer<ConversationProvider>(
      builder: (context, provider, child) {
        final conversation = provider.currentConversation;

        if (conversation == null) {
          return const Center(child: Text('Conversation not found'));
        }

        final messages = conversation.messages;

        if (messages.isEmpty) {
          return const Center(child: Text('No messages in this conversation'));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
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

  void _showConversationInfo() {
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    final conversation = conversationProvider.currentConversation;

    if (conversation == null) return;

    // Get total message count
    final totalMessages = conversation.messages.length;

    // Get user and AI message counts
    final userMessages = conversation.messages.where((m) => m.role == MessageRole.user).length;
    final aiMessages = conversation.messages.where((m) => m.role == MessageRole.ai).length;

    // Determine conversation type
    String typeString;
    switch (conversation.type) {
      case ConversationType.scenario:
        typeString = 'Scenario-based Conversation';
        break;
      case ConversationType.qa:
        typeString = 'Question & Answer Practice';
        break;
      case ConversationType.freeForm:
      default:
        typeString = 'Free-form Conversation';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${conversation.title}'),
            const SizedBox(height: 8),
            Text('Type: $typeString'),
            const SizedBox(height: 8),
            Text('Created: ${_formatDateTime(conversation.createdAt)}'),
            const SizedBox(height: 8),
            Text('Last activity: ${_formatDateTime(conversation.updatedAt)}'),
            const SizedBox(height: 16),
            Text('Total messages: $totalMessages'),
            Text('Your messages: $userMessages'),
            Text('AI messages: $aiMessages'),
          ],
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

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'continue':
        _continueConversation();
        break;
      case 'rename':
        _renameConversation();
        break;
      case 'delete':
        _confirmDeleteConversation();
        break;
    }
  }

  void _continueConversation() {
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    final conversation = conversationProvider.currentConversation;

    if (conversation == null) return;

    // Handle based on conversation type
    switch (conversation.type) {
      case ConversationType.scenario:
        if (conversation.scenarioId != null) {
          // Load the scenario session and navigate to scenario chat
          _continueScenarioConversation(conversation.scenarioId!);
        }
        break;
      case ConversationType.qa:
        if (conversation.qaSetId != null) {
          // Load the QA session and navigate to QA practice
          _continueQAConversation(conversation.qaSetId!);
        }
        break;
      case ConversationType.freeForm:
      default:
      // For now, just show a message that this is not supported yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Continuing free-form conversations is not supported yet')),
        );
        break;
    }
  }

  Future<void> _continueScenarioConversation(String scenarioId) async {
    try {
      final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);

      // Find the session for this conversation
      final sessions = await scenarioProvider.getAllSessions();
      final session = sessions.firstWhere(
            (s) => s.conversationId == widget.conversationId,
        orElse: () => throw Exception('Session not found'),
      );

      if (!mounted) return;

      // Navigate to the scenario chat screen
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.scenarioChat,
        arguments: {
          'sessionId': session.id,
          'conversationId': widget.conversationId,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error continuing conversation: $e')),
      );
    }
  }

  Future<void> _continueQAConversation(String qaSetId) async {
    try {
      final qaProvider = Provider.of<QAProvider>(context, listen: false);

      // Find the session for this conversation
      final sessions = await qaProvider.getAllSessions();
      final session = sessions.firstWhere(
            (s) => s.conversationId == widget.conversationId,
        orElse: () => throw Exception('Session not found'),
      );

      if (!mounted) return;

      // Navigate to the QA practice screen
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.qnaPractice,
        arguments: {
          'sessionId': session.sessionId,
          'conversationId': widget.conversationId,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error continuing conversation: $e')),
      );
    }
  }

  void _renameConversation() {
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    final conversation = conversationProvider.currentConversation;

    if (conversation == null) return;

    final TextEditingController controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.of(context).pop();
                await conversationProvider.updateConversationTitle(newTitle);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _confirmDeleteConversation() {
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    final conversation = conversationProvider.currentConversation;

    if (conversation == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${conversation.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await conversationProvider.deleteConversation(widget.conversationId);

              if (success && mounted) {
                Navigator.of(context).pop(); // Return to history list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conversation deleted')),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (dateToCheck == today) {
      return 'Today, $time';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, $time';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $time';
    }
  }
}