// lib/models/conversation_model.dart

import 'package:flutter/foundation.dart';

enum MessageRole { user, ai }

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final String? correctedContent;
  final String? pronunciationFeedback;

  Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.correctedContent,
    this.pronunciationFeedback,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.ai,
      timestamp: DateTime.parse(json['timestamp']),
      correctedContent: json['correctedContent'],
      pronunciationFeedback: json['pronunciationFeedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role == MessageRole.user ? 'user' : 'ai',
      'timestamp': timestamp.toIso8601String(),
      'correctedContent': correctedContent,
      'pronunciationFeedback': pronunciationFeedback,
    };
  }
}

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;
  final String? scenarioId;
  final String? qaSetId;
  final ConversationType type;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.type,
    this.scenarioId,
    this.qaSetId,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List)
          .map((message) => Message.fromJson(message))
          .toList(),
      type: ConversationType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => ConversationType.freeForm,
      ),
      scenarioId: json['scenarioId'],
      qaSetId: json['qaSetId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'type': type.toString().split('.').last,
      'scenarioId': scenarioId,
      'qaSetId': qaSetId,
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    ConversationType? type,
    String? scenarioId,
    String? qaSetId,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      type: type ?? this.type,
      scenarioId: scenarioId ?? this.scenarioId,
      qaSetId: qaSetId ?? this.qaSetId,
    );
  }
}

enum ConversationType {
  freeForm,  // General conversation
  scenario,  // Scenario-based conversation
  qa         // Question and answer based conversation
}