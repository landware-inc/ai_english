// lib/services/speech_service.dart

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLocaleId = 'en_US';
  final _uuid = Uuid();

  // Constructor initializes the speech services
  SpeechService() {
    _initSpeech();
    _initTts();
  }

  // Initialize speech recognition
  Future<void> _initSpeech() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => Logger.error("Speech recognition error: $error"),
        onStatus: (status) =>
            Logger.debug("Speech recognition status: $status"),
      );
    } catch (e) {
      Logger.error("Failed to initialize speech recognition: $e");
      _isInitialized = false;
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_currentLocaleId);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // 엔진 확인 및 설정
      List<dynamic> engines = await _flutterTts.getEngines;
      Logger.debug("Available engines: $engines");
      if (engines.contains("com.google.android.tts")) {
        await _flutterTts.setEngine("com.google.android.tts");
      }

      // 아래 코드 추가
      List<dynamic> voices = await _flutterTts.getVoices;
      Logger.debug("Available voices: $voices");

      // 미국 영어 음성 찾아 설정
      for (var voice in voices) {
        if (voice is Map && voice['locale'] == 'en-US') {
          Logger.debug("Setting voice to: $voice");
          // 타입 캐스팅을 통해 Map<String, String>으로 변환
          Map<String, String> voiceMap = {
            'name': voice['name'].toString(),
            'locale': voice['locale'].toString()
          };
          await _flutterTts.setVoice(voiceMap);
          break;
        }
      }

      _flutterTts.setCompletionHandler(() {
        Logger.debug("TTS completed");
      });

      _flutterTts.setErrorHandler((error) {
        Logger.error("TTS error: $error");
      });
    } catch (e) {
      Logger.error("Failed to initialize text-to-speech: $e");
    }
  }

  // Get available speech recognition locales
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) await _initSpeech();

    final locales = await _speech.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  // Set the speech recognition and TTS locale
  Future<void> setLocale(String localeId) async {
    localeId = 'en_US'; // For now, only support 'en_US
    _currentLocaleId = localeId;
    await _flutterTts.setLanguage(localeId);
  }

  // Start listening for speech input
  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onListeningStarted,
    required VoidCallback onListeningFinished,
    required Function(String) onError,
    int listenTimeoutSeconds = 30,
  }) async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => Logger.error("Speech recognition error: $error"),
        onStatus: (status) =>
            Logger.debug("Speech recognition status: $status"),
      );

      if (!_isInitialized) {
        onError("Failed to initialize speech recognition");
        return;
      }
    }

    if (_speech.isAvailable && !_isListening) {
      _isListening = true;
      onListeningStarted();

      await _speech.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          onResult(recognizedWords);
        },
        listenFor: Duration(seconds: listenTimeoutSeconds),
        localeId: _currentLocaleId,
        onSoundLevelChange: (level) {
          // Could be used for visualizing sound level
        },
      );

      _speech.statusListener = (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onListeningFinished();
        }
      };
    } else {
      onError("Speech recognition not available or already listening");
    }
  }

  // Stop listening for speech input
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  // Record audio to a file and return the file path
  Future<String?> recordAudio({
    required VoidCallback onRecordingStarted,
    required VoidCallback onRecordingFinished,
    required Function(String) onError,
    int recordingTimeoutSeconds = 30,
  }) async {
    // This is a placeholder for audio recording functionality
    // You would use a package like record or flutter_sound for this

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/${_uuid.v4()}.wav';

      onRecordingStarted();

      // Recording logic would go here
      // For now, we'll just wait to simulate recording
      await Future.delayed(Duration(seconds: 3));

      onRecordingFinished();
      return filePath;
    } catch (e) {
      Logger.error("Error recording audio: $e");
      onError("Failed to record audio: $e");
      return null;
    }
  }

  // Speak text using TTS
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  // Check if TTS is currently speaking
  Future<bool> isSpeaking() async {
    return await _flutterTts.getEngines.then((_) async {
      try {
        // Try to use the speaking property if available
        final isSpeaking = await _flutterTts.awaitSpeakCompletion(false);
        return !isSpeaking;
      } catch (_) {
        // Fallback - assume not speaking if we can't check
        Logger.debug("Could not determine TTS speaking state, assuming not speaking");
        return false;
      }
    });
  }

  // Dispose of resources
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
  }
}