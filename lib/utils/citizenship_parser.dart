// lib/utils/citizenship_parser.dart

import 'dart:convert';
import '../models/question_answer_model.dart';

class CitizenshipParser {
  // static Future<String> parseUSCitizenshipQuestions(String pdfContent) async {
  //   try {
  //     final List<QuestionAnswer> questions = [];
  //
  //     // Regular expression to match each question with its answers
  //     final regex = RegExp(
  //       r'(\d+)\.\s+(.*?)\n((?:▪.*?\n)+)',
  //       multiLine: true,
  //     );
  //
  //     final matches = regex.allMatches(pdfContent);
  //
  //     for (final match in matches) {
  //       final number = match.group(1) ?? '';
  //       final question = match.group(2)?.trim() ?? '';
  //       final answersText = match.group(3) ?? '';
  //
  //       // Extract answers
  //       final answerRegex = RegExp(r'▪\s+(.*?)$', multiLine: true);
  //       final answerMatches = answerRegex.allMatches(answersText);
  //
  //       final List<String> answers = [];
  //       for (final answerMatch in answerMatches) {
  //         final answer = answerMatch.group(1)?.trim() ?? '';
  //         if (answer.isNotEmpty) {
  //           answers.add(answer);
  //         }
  //       }
  //
  //       // Check if question has an asterisk (for 65+ year old applicants)
  //       final hasAsterisk = question.contains('*') ||
  //           pdfContent.contains('${number}. ${question}*');
  //
  //       // Extract keywords from the answer
  //       final List<String> keywords = [];
  //       for (final answer in answers) {
  //         final words = answer.split(' ')
  //             .where((word) => word.length > 3)  // Only consider words longer than 3 chars
  //             .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), ''))  // Remove punctuation
  //             .where((word) => !['that', 'what', 'when', 'where', 'which', 'with', 'would', 'your', 'from', 'have', 'this', 'they', 'their', 'there'].contains(word.toLowerCase()))  // Skip common words
  //             .toList();
  //
  //         keywords.addAll(words);
  //       }
  //
  //       // Create the question object
  //       final qa = QuestionAnswer(
  //         id: number,
  //         question: question,
  //         possibleAnswers: answers,
  //         keywords: keywords.toSet().toList(),  // Remove duplicates
  //         isMarkedWithAsterisk: hasAsterisk,
  //       );
  //
  //       questions.add(qa);
  //     }
  //
  //     // Create QA set
  //     final qaSet = QASet(
  //       id: 'us_citizenship_questions',
  //       title: 'US Citizenship Test',
  //       description: 'The official 100 civics (history and government) questions and answers for the naturalization test.',
  //       category: 'Citizenship',
  //       iconPath: 'assets/icons/citizenship.png',
  //       difficulty: 4,
  //       questions: questions,
  //     );
  //
  //     // Convert to JSON
  //     return jsonEncode(qaSet.toJson());
  //   } catch (e) {
  //     throw Exception('Failed to parse US Citizenship questions: $e');
  //   }
  // }
  static Future<String> parseUSCitizenshipQuestions(String pdfContent) async {
    // 원본 PDF 데이터에서 질문과 답변 추출
    List<Map<String, dynamic>> questions = [];

    // 줄 단위로 분할
    List<String> lines = pdfContent.split('\n');

    int currentQuestionNumber = 0;
    String currentQuestion = '';
    List<String> currentAnswers = [];
    bool isAsteriskQuestion = false;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // 빈 줄 건너뛰기
      if (line.isEmpty) continue;

      // 새로운 질문 시작 패턴: 숫자 뒤에 점이 오는 경우 (예: "1. What is...")
      RegExp questionPattern = RegExp(r'^(\d+)\.\s(.+)$');
      var match = questionPattern.firstMatch(line);

      if (match != null) {
        // 이전 질문이 있으면 저장
        if (currentQuestion.isNotEmpty && currentAnswers.isNotEmpty) {
          questions.add({
            'id': 'q$currentQuestionNumber',
            'question': currentQuestion,
            'possibleAnswers': currentAnswers,
            'keywords': extractKeywords(currentAnswers),
            'isMarkedWithAsterisk': isAsteriskQuestion,
          });
        }

        // 새 질문 시작
        currentQuestionNumber = int.parse(match.group(1)!);
        currentQuestion = match.group(2)!;
        currentAnswers = [];
        isAsteriskQuestion = line.contains('*');

      } else if (line.startsWith('▪')) {
        // 답변 추가
        String answer = line.substring(1).trim();
        if (answer.isNotEmpty) {
          currentAnswers.add(answer);
        }
      }
    }

    // 마지막 질문 추가
    if (currentQuestion.isNotEmpty && currentAnswers.isNotEmpty) {
      questions.add({
        'id': 'q$currentQuestionNumber',
        'question': currentQuestion,
        'possibleAnswers': currentAnswers,
        'keywords': extractKeywords(currentAnswers),
        'isMarkedWithAsterisk': isAsteriskQuestion,
      });
    }

    // 최종 JSON 구성
    Map<String, dynamic> qaSet = {
      'id': 'us_citizenship_questions',
      'title': 'US Citizenship Test',
      'description': 'The official 100 civics (history and government) questions and answers for the naturalization test.',
      'category': 'Citizenship',
      'iconPath': 'assets/icons/flag.png',
      'difficulty': 'Medium',
      'questions': questions,
      'isPremium': false,
    };

    return jsonEncode(qaSet);
  }

// 키워드 추출 헬퍼 함수
  static List<String> extractKeywords(List<String> answers) {
    Set<String> keywords = {};

    for (String answer in answers) {
      // 불필요한 단어 제거 후 주요 단어 추출
      List<String> words = answer
          .replaceAll(RegExp(r'[^\w\s]'), '')  // 구두점 제거
          .split(' ')
          .where((word) => word.length > 3)    // 짧은 단어 제거
          .map((word) => word.toLowerCase())
          .toList();

      keywords.addAll(words);
    }

    // 가장 중요한 키워드 최대 5개만 반환
    return keywords.take(5).toList();
  }
}