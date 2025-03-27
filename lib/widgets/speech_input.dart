// lib/widgets/speech_input.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';

class SpeechInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isProcessing;
  final String processingStatus;

  const SpeechInput({
    Key? key,
    required this.onSendMessage,
    this.isProcessing = false,
    this.processingStatus = '',
  }) : super(key: key);

  @override
  State<SpeechInput> createState() => _SpeechInputState();
}

class _SpeechInputState extends State<SpeechInput> {
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  String _recognizedText = '';
  String _listeningStatus = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Processing or listening status indicator
        if (widget.isProcessing || _isListening)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: widget.isProcessing
                ? Colors.blue.shade50
                : Colors.green.shade50,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isProcessing
                          ? Colors.blue
                          : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isProcessing
                      ? widget.processingStatus
                      : _listeningStatus,
                  style: TextStyle(
                    color: widget.isProcessing
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

        // Input area
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (text) {
                      setState(() {
                        _recognizedText = text;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Voice input button
                _buildVoiceButton(),

                const SizedBox(width: 8),

                // Send button
                _buildSendButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceButton() {
    return Consumer<SpeechService>(
      builder: (context, speechService, child) {
        return GestureDetector(
          onLongPress: () => _startListening(speechService),
          onLongPressEnd: (_) => _stopListening(speechService),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _recognizedText.isNotEmpty && !widget.isProcessing
                  ? Colors.blue
                  : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isListening ? Colors.red : Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
        ),
      ),
    );
  }

  void _startListening(SpeechService speechService) {
    if (widget.isProcessing) return;

    setState(() {
      _isListening = true;
      _listeningStatus = 'Listening...';
    });

    speechService.startListening(
      onResult: (result) {
        setState(() {
          _textController.text = result;
          _recognizedText = result;
        });
      },
      onListeningStarted: () {
        setState(() {
          _listeningStatus = 'Listening...';
        });
      },
      onListeningFinished: () {
        setState(() {
          _isListening = false;
          _listeningStatus = '';
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _listeningStatus = 'Error: $error';
        });

        // Show error as snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: $error')),
        );
      },
    );
  }

  void _stopListening(SpeechService speechService) {
    if (_isListening) {
      speechService.stopListening();
    }
  }

  void _sendMessage() {
    if (widget.isProcessing) return;

    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _textController.clear();
      setState(() {
        _recognizedText = '';
      });
    }
  }
}
