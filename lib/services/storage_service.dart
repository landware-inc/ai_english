// lib/services/storage_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';
import '../models/question_answer_model.dart';
import '../models/scenario_model.dart';
import '../utils/logger.dart';

class StorageService {
  // Shared Preferences instance
  late SharedPreferences _prefs;

  // Keys for various stored items
  static const String _conversationsKey = 'conversations';
  static const String _qaSessionsKey = 'qa_sessions';
  static const String _scenarioSessionsKey = 'scenario_sessions';
  static const String _userSettingsKey = 'user_settings';

  // Directory paths
  late String _appDocDir;
  late String _qaDir;
  late String _audioDir;

  // Initialize storage service
  Future<void> init() async {
    try {
      // Initialize shared preferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize directories
      final appDir = await getApplicationDocumentsDirectory();
      _appDocDir = appDir.path;

      // Create subdirectories
      _qaDir = '$_appDocDir/qa';
      _audioDir = '$_appDocDir/audio';

      await Directory(_qaDir).create(recursive: true);
      await Directory(_audioDir).create(recursive: true);

      Logger.debug('Storage service initialized');
    } catch (e) {
      Logger.error('Failed to initialize storage service: $e');
      throw Exception('Failed to initialize storage service: $e');
    }
  }

  // CONVERSATION STORAGE METHODS

  // Save a conversation
  Future<void> saveConversation(Conversation conversation) async {
    try {
      // Get existing conversations
      final List<Conversation> conversations = await getConversations();

      // Add or update the conversation
      final existingIndex = conversations.indexWhere((c) => c.id == conversation.id);
      if (existingIndex >= 0) {
        conversations[existingIndex] = conversation;
      } else {
        conversations.add(conversation);
      }

      // Convert to JSON and save
      final conversationsJson = conversations.map((c) => c.toJson()).toList();
      await _prefs.setString(_conversationsKey, jsonEncode(conversationsJson));

      Logger.debug('Saved conversation: ${conversation.id}');
    } catch (e) {
      Logger.error('Failed to save conversation: $e');
      throw Exception('Failed to save conversation: $e');
    }
  }

  // Get all conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final String? conversationsJson = _prefs.getString(_conversationsKey);

      if (conversationsJson == null || conversationsJson.isEmpty) {
        return [];
      }

      final List<dynamic> conversationsList = jsonDecode(conversationsJson);
      return conversationsList
          .map((json) => Conversation.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Failed to get conversations: $e');
      return [];
    }
  }

  // Get a specific conversation by ID
  // Future<Conversation?> getConversationById(String id) async {
  //   try {
  //     final List<Conversation> conversations = await getConversations();
  //     return conversations.firstWhere((c) => c.id == id);
  //   } catch (e) {
  //     Logger.error('Failed to get conversation by ID: $e');
  //     return null;
  //   }
  // }
  Future<Conversation?> getConversationById(String id) async {
    try {
      final List<Conversation> conversations = await getConversations();
      try {
        return conversations.firstWhere((c) => c.id == id);
      } on StateError {
        // 일치하는 항목이 없는 경우
        return null;
      }
    } catch (e) {
      Logger.error('Failed to get conversation by ID: $e');
      return null;
    }
  }

  // Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final List<Conversation> conversations = await getConversations();
      final newList = conversations.where((c) => c.id != conversationId).toList();

      final conversationsJson = newList.map((c) => c.toJson()).toList();
      await _prefs.setString(_conversationsKey, jsonEncode(conversationsJson));

      Logger.debug('Deleted conversation: $conversationId');
      return true;
    } catch (e) {
      Logger.error('Failed to delete conversation: $e');
      return false;
    }
  }

  // QA SESSION STORAGE METHODS

  // Save a QA session
  Future<void> saveQASession(QASessionProgress session) async {
    try {
      // Get existing sessions
      final List<QASessionProgress> sessions = await getQASessions();

      // Add or update the session
      final existingIndex = sessions.indexWhere((s) => s.sessionId == session.sessionId);
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      // Convert to JSON and save
      final sessionsJson = sessions.map((s) => s.toJson()).toList();
      await _prefs.setString(_qaSessionsKey, jsonEncode(sessionsJson));

      Logger.debug('Saved QA session: ${session.sessionId}');
    } catch (e) {
      Logger.error('Failed to save QA session: $e');
      throw Exception('Failed to save QA session: $e');
    }
  }

  // Get all QA sessions
  Future<List<QASessionProgress>> getQASessions() async {
    try {
      final String? sessionsJson = _prefs.getString(_qaSessionsKey);

      if (sessionsJson == null || sessionsJson.isEmpty) {
        return [];
      }

      final List<dynamic> sessionsList = jsonDecode(sessionsJson);
      return sessionsList
          .map((json) => QASessionProgress.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Failed to get QA sessions: $e');
      return [];
    }
  }

  // Get a specific QA session by ID
  Future<QASessionProgress?> getQASessionById(String sessionId) async {
    try {
      final List<QASessionProgress> sessions = await getQASessions();
      return sessions.firstWhere((s) => s.sessionId == sessionId);
    } catch (e) {
      Logger.error('Failed to get QA session by ID: $e');
      return null;
    }
  }

  // Delete a QA session
  Future<bool> deleteQASession(String sessionId) async {
    try {
      final List<QASessionProgress> sessions = await getQASessions();
      final newList = sessions.where((s) => s.sessionId != sessionId).toList();

      final sessionsJson = newList.map((s) => s.toJson()).toList();
      await _prefs.setString(_qaSessionsKey, jsonEncode(sessionsJson));

      Logger.debug('Deleted QA session: $sessionId');
      return true;
    } catch (e) {
      Logger.error('Failed to delete QA session: $e');
      return false;
    }
  }

  // SCENARIO SESSION STORAGE METHODS

  // Save a scenario session
  Future<void> saveScenarioSession(ScenarioSession session) async {
    try {
      // Get existing sessions
      final List<ScenarioSession> sessions = await getScenarioSessions();

      // Add or update the session
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }

      // Convert to JSON and save
      final sessionsJson = sessions.map((s) => s.toJson()).toList();
      await _prefs.setString(_scenarioSessionsKey, jsonEncode(sessionsJson));

      Logger.debug('Saved scenario session: ${session.id}');
    } catch (e) {
      Logger.error('Failed to save scenario session: $e');
      throw Exception('Failed to save scenario session: $e');
    }
  }

  // Get all scenario sessions
  Future<List<ScenarioSession>> getScenarioSessions() async {
    try {
      final String? sessionsJson = _prefs.getString(_scenarioSessionsKey);

      if (sessionsJson == null || sessionsJson.isEmpty) {
        return [];
      }

      final List<dynamic> sessionsList = jsonDecode(sessionsJson);
      return sessionsList
          .map((json) => ScenarioSession.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Failed to get scenario sessions: $e');
      return [];
    }
  }

  // Get a specific scenario session by ID
  Future<ScenarioSession?> getScenarioSessionById(String sessionId) async {
    try {
      final List<ScenarioSession> sessions = await getScenarioSessions();
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      Logger.error('Failed to get scenario session by ID: $e');
      return null;
    }
  }

  // Delete a scenario session
  Future<bool> deleteScenarioSession(String sessionId) async {
    try {
      final List<ScenarioSession> sessions = await getScenarioSessions();
      final newList = sessions.where((s) => s.id != sessionId).toList();

      final sessionsJson = newList.map((s) => s.toJson()).toList();
      await _prefs.setString(_scenarioSessionsKey, jsonEncode(sessionsJson));

      Logger.debug('Deleted scenario session: $sessionId');
      return true;
    } catch (e) {
      Logger.error('Failed to delete scenario session: $e');
      return false;
    }
  }

  // QA DATA MANAGEMENT METHODS

  // Save QA dataset file
  Future<bool> saveQADataset(String fileName, String jsonContent) async {
    try {
      final file = File('$_qaDir/$fileName.json');
      await file.writeAsString(jsonContent);
      Logger.debug('Saved QA dataset: $fileName');
      return true;
    } catch (e) {
      Logger.error('Failed to save QA dataset: $e');
      return false;
    }
  }

  // Read QA dataset file
  Future<String?> readQADataset(String fileName) async {
    try {
      final file = File('$_qaDir/$fileName.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      Logger.error('Failed to read QA dataset: $e');
      return null;
    }
  }

  // List available QA datasets
  Future<List<String>> listQADatasets() async {
    try {
      final dir = Directory(_qaDir);
      final List<FileSystemEntity> files = await dir.list().toList();
      return files
          .whereType<File>()
          .map((file) => file.path.split('/').last.replaceAll('.json', ''))
          .toList();
    } catch (e) {
      Logger.error('Failed to list QA datasets: $e');
      return [];
    }
  }

  // Delete QA dataset file
  Future<bool> deleteQADataset(String fileName) async {
    try {
      final file = File('$_qaDir/$fileName.json');
      if (await file.exists()) {
        await file.delete();
        Logger.debug('Deleted QA dataset: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to delete QA dataset: $e');
      return false;
    }
  }

  // AUDIO RECORDING MANAGEMENT

  // Save audio recording
  Future<String?> saveAudioRecording(String conversationId, File audioFile) async {
    try {
      final fileName = '${conversationId}_${DateTime.now().millisecondsSinceEpoch}.wav';
      final destination = File('$_audioDir/$fileName');

      await audioFile.copy(destination.path);
      Logger.debug('Saved audio recording: $fileName');
      return destination.path;
    } catch (e) {
      Logger.error('Failed to save audio recording: $e');
      return null;
    }
  }

  // Get audio recordings for a conversation
  Future<List<String>> getAudioRecordings(String conversationId) async {
    try {
      final dir = Directory(_audioDir);
      final List<FileSystemEntity> files = await dir.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.contains(conversationId))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      Logger.error('Failed to get audio recordings: $e');
      return [];
    }
  }

  // Delete audio recording
  Future<bool> deleteAudioRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Logger.debug('Deleted audio recording: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Failed to delete audio recording: $e');
      return false;
    }
  }

  // USER SETTINGS METHODS

  // Save user settings
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    try {
      await _prefs.setString(_userSettingsKey, jsonEncode(settings));
      Logger.debug('Saved user settings');
    } catch (e) {
      Logger.error('Failed to save user settings: $e');
      throw Exception('Failed to save user settings: $e');
    }
  }

  // Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final String? settingsJson = _prefs.getString(_userSettingsKey);

      if (settingsJson == null || settingsJson.isEmpty) {
        return {}; // Return empty settings if none exist
      }

      return jsonDecode(settingsJson);
    } catch (e) {
      Logger.error('Failed to get user settings: $e');
      return {};
    }
  }

  // Update a specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      final settings = await getUserSettings();
      settings[key] = value;
      await saveUserSettings(settings);
      Logger.debug('Updated setting: $key');
    } catch (e) {
      Logger.error('Failed to update setting: $e');
      throw Exception('Failed to update setting: $e');
    }
  }

  // Clear all data (for account reset or logout)
  Future<bool> clearAllData() async {
    try {
      // Clear preferences
      await _prefs.clear();

      // Clear directories
      await Directory(_qaDir).delete(recursive: true);
      await Directory(_audioDir).delete(recursive: true);

      // Recreate directories
      await Directory(_qaDir).create(recursive: true);
      await Directory(_audioDir).create(recursive: true);

      Logger.debug('Cleared all data');
      return true;
    } catch (e) {
      Logger.error('Failed to clear all data: $e');
      return false;
    }
  }
}