// lib/models/question_answer_model.dart

import 'package:flutter/foundation.dart';

class QASet {
  final String id;
  final String title;
  final String description;
  final String category;
  final String iconPath;
  final int difficulty; // 1-5, where 5 is most difficult
  final List<QuestionAnswer> questions;
  final bool isPremium;

  QASet({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconPath,
    required this.difficulty,
    required this.questions,
    this.isPremium = false,
  });

  factory QASet.fromJson(Map<String, dynamic> json) {
    // 필드에 대한 타입 변환 로직 추가
    var difficultyValue = json['difficulty'];
    int difficulty;

    if (difficultyValue is String) {
      // 문자열 difficulty를 숫자로 변환
      switch(difficultyValue.toLowerCase()) {
        case 'beginner': difficulty = 1; break;
        case 'elementary': difficulty = 2; break;
        case 'medium':
        case 'intermediate': difficulty = 3; break;
        case 'advanced': difficulty = 4; break;
        case 'expert':
        case 'hard': difficulty = 5; break;
        default: difficulty = 3; // 기본값
      }
    } else if (difficultyValue is int) {
      difficulty = difficultyValue;
    } else {
      difficulty = 3; // 기본값
    }

    return QASet(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      iconPath: json['iconPath'],
      difficulty: difficulty, // 변환된 값 사용
      questions: (json['questions'] as List)
          .map((q) => QuestionAnswer.fromJson(q))
          .toList(),
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'iconPath': iconPath,
      'difficulty': difficulty,
      'questions': questions.map((q) => q.toJson()).toList(),
      'isPremium': isPremium,
    };
  }
}

class QuestionAnswer {
  final String id;
  final String question;
  final List<String> possibleAnswers;
  final List<String> keywords; // Important keywords that should be in the answer
  final String? hint;
  final String? note; // Additional explanation about the answer
  final bool isMarkedWithAsterisk; // For US citizenship questions

  QuestionAnswer({
    required this.id,
    required this.question,
    required this.possibleAnswers,
    this.keywords = const [],
    this.hint,
    this.note,
    this.isMarkedWithAsterisk = false,
  });

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      id: json['id'],
      question: json['question'],
      possibleAnswers: List<String>.from(json['possibleAnswers']),
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'])
          : [],
      hint: json['hint'],
      note: json['note'],
      isMarkedWithAsterisk: json['isMarkedWithAsterisk'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'possibleAnswers': possibleAnswers,
      'keywords': keywords,
      'hint': hint,
      'note': note,
      'isMarkedWithAsterisk': isMarkedWithAsterisk,
    };
  }
}

class QASessionProgress {
  final String qaSetId;
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final int currentQuestionIndex;
  final int totalQuestions;
  final List<QAResponse> responses;
  final String conversationId;

  QASessionProgress({
    required this.qaSetId,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.responses,
    required this.conversationId,
  });

  factory QASessionProgress.fromJson(Map<String, dynamic> json) {
    return QASessionProgress(
      qaSetId: json['qaSetId'],
      sessionId: json['sessionId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      currentQuestionIndex: json['currentQuestionIndex'],
      totalQuestions: json['totalQuestions'],
      responses: (json['responses'] as List)
          .map((r) => QAResponse.fromJson(r))
          .toList(),
      conversationId: json['conversationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qaSetId': qaSetId,
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
      'totalQuestions': totalQuestions,
      'responses': responses.map((r) => r.toJson()).toList(),
      'conversationId': conversationId,
    };
  }

  double get progressPercentage =>
      totalQuestions > 0 ? currentQuestionIndex / totalQuestions : 0;

  bool get isCompleted => endTime != null;

  int get correctAnswers =>
      responses.where((r) => r.wasCorrect).length;

  double get scorePercentage =>
      responses.isNotEmpty ? correctAnswers / responses.length * 100 : 0;
}

class QAResponse {
  final String questionId;
  final String userAnswer;
  final bool wasCorrect;
  final String? aiEvaluation;
  final List<String> suggestedCorrectAnswers;
  final DateTime answeredAt;

  QAResponse({
    required this.questionId,
    required this.userAnswer,
    required this.wasCorrect,
    this.aiEvaluation,
    required this.suggestedCorrectAnswers,
    required this.answeredAt,
  });

  factory QAResponse.fromJson(Map<String, dynamic> json) {
    return QAResponse(
      questionId: json['questionId'],
      userAnswer: json['userAnswer'],
      wasCorrect: json['wasCorrect'],
      aiEvaluation: json['aiEvaluation'],
      suggestedCorrectAnswers: List<String>.from(json['suggestedCorrectAnswers']),
      answeredAt: DateTime.parse(json['answeredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'wasCorrect': wasCorrect,
      'aiEvaluation': aiEvaluation,
      'suggestedCorrectAnswers': suggestedCorrectAnswers,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}