// lib/providers/scenario_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/scenario_model.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

class ScenarioProvider with ChangeNotifier {
  final StorageService _storageService;
  final _uuid = Uuid();

  // Data
  List<ScenarioCategory> _categories = [];
  ScenarioSession? _currentSession;
  Scenario? _currentScenario;

  // State
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ScenarioCategory> get categories => _categories;
  ScenarioSession? get currentSession => _currentSession;
  Scenario? get currentScenario => _currentScenario;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor
  ScenarioProvider({
    required StorageService storageService,
  }) : _storageService = storageService {
    _loadScenarios();
  }

  // Load scenarios from assets/storage
  Future<void> _loadScenarios() async {
    _setLoading(true);

    try {
      // Here we could load scenarios from a local JSON file or from an API
      // For now, let's use predefined scenarios

      // This is a placeholder - in a real app, you'd load this from a file or API
      _categories = _getDefaultScenarios();

      Logger.debug('Loaded ${_categories.length} scenario categories');
    } catch (e) {
      _error = 'Failed to load scenarios: $e';
      Logger.error(_error!);
    } finally {
      _setLoading(false);
    }
  }

  // Get a specific scenario by ID
  Scenario? getScenarioById(String scenarioId) {
    for (final category in _categories) {
      for (final scenario in category.scenarios) {
        if (scenario.id == scenarioId) {
          return scenario;
        }
      }
    }
    return null;
  }

  // Set the current scenario
  void setCurrentScenario(String scenarioId) {
    final scenario = getScenarioById(scenarioId);

    if (scenario != null) {
      _currentScenario = scenario;
      Logger.debug('Set current scenario: ${scenario.name}');
    } else {
      _error = 'Scenario not found: $scenarioId';
      Logger.error(_error!);
    }

    notifyListeners();
  }

  // Create a new scenario session
  Future<ScenarioSession?> createSession({
    required String scenarioId,
    required String selectedRole,
    required List<String> selectedKeywords,
    required List<String> practicePhrasesAdded,
    required String conversationId,
  }) async {
    try {
      final scenario = getScenarioById(scenarioId);

      if (scenario == null) {
        throw Exception('Scenario not found: $scenarioId');
      }

      final sessionId = _uuid.v4();

      final session = ScenarioSession(
        id: sessionId,
        scenario: scenario,
        selectedRole: selectedRole,
        selectedKeywords: selectedKeywords,
        practicePhrasesAdded: practicePhrasesAdded,
        createdAt: DateTime.now(),
        conversationId: conversationId,
      );

      // Save the session
      await _storageService.saveScenarioSession(session);

      // Set as current session
      _currentSession = session;
      _currentScenario = scenario;

      Logger.debug('Created new scenario session: $sessionId');
      notifyListeners();

      return session;
    } catch (e) {
      _error = 'Failed to create session: $e';
      Logger.error(_error!);
      notifyListeners();
      return null;
    }
  }

  // Load an existing session
  Future<void> loadSession(String sessionId) async {
    _setLoading(true);

    try {
      final session = await _storageService.getScenarioSessionById(sessionId);

      if (session != null) {
        _currentSession = session;
        _currentScenario = session.scenario;

        Logger.debug('Loaded scenario session: $sessionId');
      } else {
        _error = 'Session not found';
        Logger.error('Failed to load session: $sessionId');
      }
    } catch (e) {
      _error = 'Failed to load session: $e';
      Logger.error(_error!);
    } finally {
      _setLoading(false);
    }
  }

  // Get all scenario sessions
  Future<List<ScenarioSession>> getAllSessions() async {
    try {
      return await _storageService.getScenarioSessions();
    } catch (e) {
      _error = 'Failed to get sessions: $e';
      Logger.error(_error!);
      return [];
    }
  }

  // Delete a session
  Future<bool> deleteSession(String sessionId) async {
    try {
      final success = await _storageService.deleteScenarioSession(sessionId);

      if (success && _currentSession?.id == sessionId) {
        _currentSession = null;
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Failed to delete session: $e';
      Logger.error(_error!);
      return false;
    }
  }

  // Generate the system prompt for a scenario
  String generateSystemPrompt() {
    if (_currentSession == null) {
      return 'Error: No active scenario session';
    }

    return _currentSession!.generateSystemPrompt();
  }

  // Handle loading state
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // MOCK DATA - In a real app, this would come from a JSON file or API
  List<ScenarioCategory> _getDefaultScenarios() {
    return [
      ScenarioCategory(
        id: 'daily_life',
        name: 'Daily Life',
        description: 'Common everyday situations',
        iconPath: 'assets/icons/daily_life.png',
        scenarios: [
          Scenario(
            id: 'restaurant',
            name: 'Restaurant',
            description: 'Practice ordering food and making reservations at a restaurant',
            promptTemplate: 'You are a {role} at a restaurant. The conversation will involve {keywords}. Respond naturally as if this is a real conversation. Ask questions and provide appropriate responses based on the role.',
            roles: ['waiter/waitress', 'customer', 'chef', 'host/hostess'],
            suggestedKeywords: ['reservation', 'menu', 'ordering', 'special requests', 'payment', 'food allergies'],
            suggestedPhrases: [
              "'I'd like to make a reservation for tonight",
              "'Could you tell me about today's specials?",
              "'I have a food allergy, can you accommodate that?",
              "'Can we get the check, please?"
            ],
            difficultyLevel: 2,
          ),
          Scenario(
            id: 'shopping',
            name: 'Shopping',
            description: 'Practice shopping for clothes, groceries, or other items',
            promptTemplate: 'You are a {role} in a shopping scenario. The conversation will involve {keywords}. Respond naturally as if this is a real conversation. Ask questions and provide appropriate responses based on the role.',
            roles: ['customer', 'sales associate', 'cashier', 'store manager'],
            suggestedKeywords: ['finding items', 'asking for help', 'trying on clothes', 'returns', 'discounts', 'sizes'],
            suggestedPhrases: [
              'Do you have this in a different size/color?',
              'Where can I find the [item]?',
              'Is this on sale?',
              "I'd like to return this item"
            ],
            difficultyLevel: 1,
          ),
        ],
      ),
    ScenarioCategory(
      id: 'professional',
      name: 'Professional',
      description: 'Work-related scenarios',
      iconPath: 'assets/icons/professional.png',
      scenarios: [
        Scenario(
          id: 'job_interview',
          name: 'Job Interview',
          description: 'Practice answering common job interview questions',
          promptTemplate: 'You are a {role} in a job interview scenario. The conversation will involve {keywords}. If you are the interviewer, ask relevant questions and provide feedback. If you are the job candidate, respond to questions professionally.',
          roles: ['interviewer', 'job candidate'],
          suggestedKeywords: ['experience', 'skills', 'strengths', 'weaknesses', 'salary', 'availability', 'background'],
          suggestedPhrases: [
            'Could you tell me about your previous experience?',
            'What are your strongest skills?',
            'Why do you want to work for this company?',
            'Where do you see yourself in five years?'
          ],
          difficultyLevel: 4,
        ),
        Scenario(
          id: 'business_meeting',
          name: 'Business Meeting',
          description: 'Practice participating in a business meeting',
          promptTemplate: 'You are a {role} in a business meeting. The conversation will involve {keywords}. Respond naturally and professionally as if this is a real business conversation.',
          roles: ['manager', 'team member', 'client', 'presenter'],
          suggestedKeywords: ['project updates', 'deadlines', 'budget', 'challenges', 'solutions', 'questions'],
          suggestedPhrases: [
            "Let's go over the project timeline",
            'What challenges are we facing?',
            "'I'd like to propose a solution",
            'Do we have the budget for this?'
          ],
          difficultyLevel: 3,
        ),
      ],
    ),
    ScenarioCategory(
      id: 'travel',
      name: 'Travel',
      description: 'Scenarios for travelers',
      iconPath: 'assets/icons/travel.png',
      scenarios: [
        Scenario(
          id: 'hotel_checkin',
          name: 'Hotel Check-in',
          description: 'Practice checking into a hotel and asking about facilities',
          promptTemplate: 'You are a {role} in a hotel check-in scenario. The conversation will involve {keywords}. Respond naturally as if this is a real conversation at a hotel.',
          roles: ['guest', 'receptionist', 'concierge', 'hotel manager'],
          suggestedKeywords: ['reservation', 'room preferences', 'hotel facilities', 'local attractions', 'issues', 'checkout time'],
          suggestedPhrases: [
            'I have a reservation under the name...',
            'What time is breakfast served?',
            'Is there WiFi available?',
            'Could you recommend any local restaurants?'
          ],
          difficultyLevel: 2,
        ),
        Scenario(
          id: 'airport',
          name: 'Airport',
          description: 'Practice navigating an airport and flight-related conversations',
          promptTemplate: 'You are a {role} in an airport scenario. The conversation will involve {keywords}. Respond naturally as if this is a real conversation at an airport.',
          roles: ['passenger', 'check-in agent', 'security officer', 'flight attendant'],
          suggestedKeywords: ['check-in', 'baggage', 'delays', 'boarding', 'security', 'directions'],
          suggestedPhrases: [
            "I'd like to check in for my flight to...",
            'Is my flight on time?',
            'Where is the gate for flight number...?',
            'Do I need to remove my laptop for security?'
          ],
          difficultyLevel: 3,
        ),
      ],
    ),
    ScenarioCategory(
      id: 'emergency',
      name: 'Emergency',
      description: 'Emergency situations',
      iconPath: 'assets/icons/emergency.png',
      scenarios: [
        Scenario(
          id: 'medical_emergency',
          name: 'Medical Emergency',
          description: 'Practice communicating in a medical emergency',
          promptTemplate: 'You are a {role} in a medical emergency scenario. The conversation will involve {keywords}. Respond appropriately for the situation.',
          roles: ['patient', 'doctor', 'nurse', 'paramedic', 'family member'],
          suggestedKeywords: ['symptoms', 'medical history', 'allergies', 'pain level', 'treatment', 'insurance'],
          suggestedPhrases: [
            'I need medical assistance',
            'Where does it hurt?',
            "I'm allergic to...",
            'When did the symptoms start?'
          ],
          difficultyLevel: 4,
          isPremium: true,
        ),
        Scenario(
          id: 'lost_passport',
          name: 'Lost Passport',
          description: 'Practice reporting and handling a lost passport situation',
          promptTemplate: 'You are a {role} in a lost passport scenario. The conversation will involve {keywords}. Respond appropriately for the situation.',
          roles: ['traveler', 'embassy official', 'police officer', 'hotel staff'],
          suggestedKeywords: ['reporting loss', 'identification', 'embassy', 'police report', 'temporary documents'],
          suggestedPhrases: [
            "I've lost my passport",
            'What documents do I need to bring?',
            'How long will it take to get a replacement?',
            'I need to file a police report'
          ],
          difficultyLevel: 3,
          isPremium: true,
        ),
      ],
    ),
    ScenarioCategory(
      id: 'citizenship',
      name: 'Citizenship',
      description: 'Scenarios related to citizenship and immigration',
      iconPath: 'assets/icons/citizenship.png',
      scenarios: [
        Scenario(
          id: 'citizenship_interview',
          name: 'Citizenship Interview',
          description: 'Practice for a US citizenship interview',
          promptTemplate: 'You are a {role} in a US citizenship interview. The conversation will involve {keywords}. If you are the officer, ask relevant questions from the citizenship test. If you are the applicant, respond to questions accurately.',
          roles: ['USCIS officer', 'citizenship applicant'],
          suggestedKeywords: ['civics test', 'history questions', 'government questions', 'personal information', 'oath of allegiance'],
          suggestedPhrases: [
            'What is the supreme law of the land?',
            'What are the rights in the Declaration of Independence?',
            'How many U.S. Senators are there?',
            'What is the economic system of the United States?'
          ],
          difficultyLevel: 5,
        ),
        Scenario(
          id: 'visa_application',
          name: 'Visa Application',
          description: 'Practice a visa application interview',
          promptTemplate: 'You are a {role} in a visa application scenario. The conversation will involve {keywords}. Respond appropriately based on the role.',
          roles: ['visa applicant', 'consular officer', 'immigration attorney'],
          suggestedKeywords: ['purpose of travel', 'length of stay', 'ties to home country', 'financial support', 'visa requirements'],
          suggestedPhrases: [
            'What is the purpose of your visit?',
            'How long do you plan to stay?',
            'Do you have ties to your home country?',
            'How will you support yourself during your stay?'
          ],
          difficultyLevel: 4,
          isPremium: true,
        ),
      ],
    ),
    ];
    }
}