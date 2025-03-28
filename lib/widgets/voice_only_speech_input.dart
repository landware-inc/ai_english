// lib/widgets/voice_only_speech_input.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';

class VoiceOnlySpeechInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isProcessing;
  final String processingStatus;
  final bool autoActivate;

  const VoiceOnlySpeechInput({
    Key? key,
    required this.onSendMessage,
    this.isProcessing = false,
    this.processingStatus = '',
    this.autoActivate = false,
  }) : super(key: key);

  @override
  State<VoiceOnlySpeechInput> createState() => _VoiceOnlySpeechInputState();
}

class _VoiceOnlySpeechInputState extends State<VoiceOnlySpeechInput> {
  bool _isListening = false;
  String _recognizedText = '';
  String _listeningStatus = '';
  bool _micActivationPending = false;

  @override
  void initState() {
    super.initState();

    // Auto-activate microphone if requested (will be checked if TTS is not speaking first)
    if (widget.autoActivate) {
      setState(() {
        _micActivationPending = true;
      });

      // Check on next frame if TTS is speaking
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndActivateMicrophone();
      });
    }
  }

  // Check if TTS is speaking and only activate microphone if it's not
  Future<void> _checkAndActivateMicrophone() async {
    if (!mounted) return;

    final speechService = Provider.of<SpeechService>(context, listen: false);
    final isSpeaking = await speechService.isSpeaking();

    if (!isSpeaking && _micActivationPending && mounted) {
      setState(() {
        _micActivationPending = false;
      });
      _activateMicrophone(speechService);
    } else if (isSpeaking && _micActivationPending && mounted) {
      // If TTS is speaking, wait for it to finish and then check again
      speechService.onTtsCompletion(() {
        if (mounted) {
          _checkAndActivateMicrophone();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final speechService = Provider.of<SpeechService>(context);
    final isTtsSpeaking = speechService.isSpeakingSync;

    return Column(
      children: [
        // Recognized text display - always show this container but with empty or filled content
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your answer:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _recognizedText.isEmpty
                    ? isTtsSpeaking
                    ? 'Waiting for question to finish...'
                    : 'Tap microphone to speak...'
                    : _recognizedText,
                style: TextStyle(
                  color: _recognizedText.isEmpty ? Colors.grey.shade500 : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Processing or listening status indicator
        if (widget.isProcessing || _isListening || isTtsSpeaking)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: widget.isProcessing
                ? Colors.blue.shade50
                : _isListening
                ? Colors.green.shade50
                : Colors.yellow.shade50,
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
                          : _isListening
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isProcessing
                      ? widget.processingStatus
                      : _isListening
                      ? 'Listening...'
                      : isTtsSpeaking
                      ? 'Reading question...'
                      : 'Tap microphone to speak',
                  style: TextStyle(
                    color: widget.isProcessing
                        ? Colors.blue.shade700
                        : _isListening
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

        // Microphone button and submit
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
            vertical: 16,
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Microphone button
                Consumer<SpeechService>(
                  builder: (context, speechService, child) {
                    final bool isTtsSpeaking = speechService.isSpeakingSync;
                    final bool micDisabled = widget.isProcessing || isTtsSpeaking;

                    return GestureDetector(
                      onTap: micDisabled
                          ? null
                          : () => _toggleListening(speechService),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red
                              : micDisabled
                              ? Colors.grey
                              : Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _isListening
                                  ? Icons.mic
                                  : Icons.mic_none,
                              color: Colors.white,
                              size: 36,
                            ),
                            if (isTtsSpeaking)
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.volume_up,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Submit button - only show when we have recognized text and not listening/processing/TTS speaking
                if (_recognizedText.isNotEmpty && !_isListening && !widget.isProcessing)
                  Consumer<SpeechService>(
                    builder: (context, speechService, child) {
                      final bool isTtsSpeaking = speechService.isSpeakingSync;

                      if (isTtsSpeaking) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: ElevatedButton(
                          onPressed: _sendRecognizedText,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleListening(SpeechService speechService) {
    if (_isListening) {
      // If currently listening, stop
      _stopListening(speechService);
    } else {
      // If not listening, check if TTS is speaking first
      _activateMicrophoneIfNotSpeaking(speechService);
    }
  }

  // New method to check TTS status before activating microphone
  Future<void> _activateMicrophoneIfNotSpeaking(SpeechService speechService) async {
    final isSpeaking = await speechService.isSpeaking();

    if (!isSpeaking) {
      _activateMicrophone(speechService);
    } else {
      // Show a message that we can't start listening while TTS is speaking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the question to finish...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _activateMicrophone(SpeechService speechService) {
    if (widget.isProcessing) return;

    // Clear previous recognized text if we're starting fresh
    setState(() {
      _isListening = true;
      _listeningStatus = 'Listening...';
      // Don't clear _recognizedText here - allow user to make corrections
    });

    speechService.startListening(
      onResult: (result) {
        setState(() {
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
          _listeningStatus = '';
        });

        // Show error as snackbar
        if (error.contains("while TTS is speaking")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please wait for the question to finish')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech recognition error: $error')),
          );
        }
      },
    );
  }

  void _stopListening(SpeechService speechService) {
    if (_isListening) {
      speechService.stopListening();
    }
  }

  void _sendRecognizedText() {
    if (_recognizedText.trim().isNotEmpty) {
      widget.onSendMessage(_recognizedText);

      setState(() {
        _recognizedText = '';
      });
    }
  }
}