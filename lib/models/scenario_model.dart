// lib/models/scenario_model.dart

import 'package:flutter/foundation.dart';

class ScenarioCategory {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final List<Scenario> scenarios;

  ScenarioCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.scenarios,
  });

  factory ScenarioCategory.fromJson(Map<String, dynamic> json) {
    return ScenarioCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconPath: json['iconPath'],
      scenarios: (json['scenarios'] as List)
          .map((scenario) => Scenario.fromJson(scenario))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
    };
  }
}

class Scenario {
  final String id;
  final String name;
  final String description;
  final String promptTemplate;
  final List<String> roles;
  final List<String> suggestedKeywords;
  final List<String> suggestedPhrases;
  final int difficultyLevel; // 1-5, where 5 is most difficult
  final bool isPremium;

  Scenario({
    required this.id,
    required this.name,
    required this.description,
    required this.promptTemplate,
    required this.roles,
    required this.suggestedKeywords,
    required this.suggestedPhrases,
    required this.difficultyLevel,
    this.isPremium = false,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      promptTemplate: json['promptTemplate'],
      roles: List<String>.from(json['roles']),
      suggestedKeywords: List<String>.from(json['suggestedKeywords']),
      suggestedPhrases: List<String>.from(json['suggestedPhrases']),
      difficultyLevel: json['difficultyLevel'],
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'promptTemplate': promptTemplate,
      'roles': roles,
      'suggestedKeywords': suggestedKeywords,
      'suggestedPhrases': suggestedPhrases,
      'difficultyLevel': difficultyLevel,
      'isPremium': isPremium,
    };
  }
}

class ScenarioSession {
  final String id;
  final Scenario scenario;
  final String selectedRole;
  final List<String> selectedKeywords;
  final List<String> practicePhrasesAdded;
  final DateTime createdAt;
  final String conversationId;

  ScenarioSession({
    required this.id,
    required this.scenario,
    required this.selectedRole,
    required this.selectedKeywords,
    required this.practicePhrasesAdded,
    required this.createdAt,
    required this.conversationId,
  });

  factory ScenarioSession.fromJson(Map<String, dynamic> json) {
    return ScenarioSession(
      id: json['id'],
      scenario: Scenario.fromJson(json['scenario']),
      selectedRole: json['selectedRole'],
      selectedKeywords: List<String>.from(json['selectedKeywords']),
      practicePhrasesAdded: List<String>.from(json['practicePhrasesAdded']),
      createdAt: DateTime.parse(json['createdAt']),
      conversationId: json['conversationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenario': scenario.toJson(),
      'selectedRole': selectedRole,
      'selectedKeywords': selectedKeywords,
      'practicePhrasesAdded': practicePhrasesAdded,
      'createdAt': createdAt.toIso8601String(),
      'conversationId': conversationId,
    };
  }

  String generateSystemPrompt() {
    // This interpolates the user's choices into the scenario prompt template
    String prompt = scenario.promptTemplate;

    prompt = prompt.replaceAll('{role}', selectedRole);
    prompt = prompt.replaceAll('{keywords}', selectedKeywords.join(', '));

    if (practicePhrasesAdded.isNotEmpty) {
      prompt += "\n\nGuide the conversation to allow the user to practice these phrases: ${practicePhrasesAdded.join(', ')}";
    }

    prompt += "\n\nProvide natural corrections for grammar, vocabulary, or pronunciation issues. If the user's English is awkward or incorrect, suggest a more natural phrasing. Mark corrections with [correct: your suggestion]";

    return prompt;
  }
}