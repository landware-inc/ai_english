// lib/widgets/conversation_bubble.dart

import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/speech_service.dart';
import 'package:provider/provider.dart';

class ConversationBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onTapCorrection;

  const ConversationBubble({
    Key? key,
    required this.message,
    this.onTapCorrection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) _buildAvatar(isUserMessage),

          const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildBubble(context, isUserMessage),

                if (message.correctedContent != null ||
                    message.pronunciationFeedback != null)
                  _buildCorrectionIndicator(context),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (isUserMessage) _buildAvatar(isUserMessage),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Colors.blue.shade700 : Colors.purple.shade700,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isUser) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue.shade100
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionIndicator(BuildContext context) {
    return GestureDetector(
      onTap: onTapCorrection,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.orange.shade800,
            ),
            const SizedBox(width: 4),
            Text(
              'Feedback available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final speechService = Provider.of<SpeechService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Read aloud'),
              onTap: () {
                Navigator.of(context).pop();
                speechService.speak(message.content);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () {
                // Copy to clipboard
                // Clipboard.setData(ClipboardData(text: message.content));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (message.correctedContent != null || message.pronunciationFeedback != null)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View feedback'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (onTapCorrection != null) {
                    onTapCorrection!();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    String timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeStr';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}, $timeStr';
    }
  }
}