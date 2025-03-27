// lib/routes.dart

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scenario/scenario_list_screen.dart';
import 'screens/scenario/scenario_detail_screen.dart';
import 'screens/scenario/scenario_chat_screen.dart';
import 'screens/qna/qna_list_screen.dart';
import 'screens/qna/qna_detail_screen.dart';
import 'screens/qna/qna_practice_screen.dart';
import 'screens/history/history_list_screen.dart';
import 'screens/history/history_detail_screen.dart';
import 'screens/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String scenarioList = '/scenarios';
  static const String scenarioDetail = '/scenarios/detail';
  static const String scenarioChat = '/scenarios/chat';
  static const String qnaList = '/qna';
  static const String qnaDetail = '/qna/detail';
  static const String qnaPractice = '/qna/practice';
  static const String historyList = '/history';
  static const String historyDetail = '/history/detail';
  static const String c_settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case scenarioList:
        return MaterialPageRoute(builder: (_) => const ScenarioListScreen());
      case scenarioDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final scenarioId = args?['scenarioId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ScenarioDetailScreen(scenarioId: scenarioId),
        );
      case scenarioChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final sessionId = args?['sessionId'] as String? ?? '';
        final conversationId = args?['conversationId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ScenarioChatScreen(
            sessionId: sessionId,
            conversationId: conversationId,
          ),
        );
      case qnaList:
        return MaterialPageRoute(builder: (_) => const QnAListScreen());
      case qnaDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final qaSetId = args?['qaSetId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => QnADetailScreen(qaSetId: qaSetId),
        );
      case qnaPractice:
        final args = settings.arguments as Map<String, dynamic>?;
        final sessionId = args?['sessionId'] as String? ?? '';
        final conversationId = args?['conversationId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => QnAPracticeScreen(
            sessionId: sessionId,
            conversationId: conversationId,
          ),
        );
      case historyList:
        return MaterialPageRoute(builder: (_) => const HistoryListScreen());
      case historyDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final conversationId = args?['conversationId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => HistoryDetailScreen(conversationId: conversationId),
        );
      case c_settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}