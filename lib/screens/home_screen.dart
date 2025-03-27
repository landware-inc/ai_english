// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI English Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.c_settings);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Welcome to AI English Practice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Improve your English with AI-powered conversation practice. Choose a mode below to get started.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mode selection heading
            const Text(
              'Choose Practice Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Practice modes
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Scenario-based practice
                  _buildPracticeCard(
                    context: context,
                    title: 'Scenario Practice',
                    icon: Icons.forum,
                    color: Colors.blue,
                    description: 'Practice real-life conversations in various scenarios',
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.scenarioList);
                    },
                  ),

                  // Q&A practice
                  _buildPracticeCard(
                    context: context,
                    title: 'Q&A Practice',
                    icon: Icons.question_answer,
                    color: Colors.green,
                    description: 'Practice answering specific questions from question sets',
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.qnaList);
                    },
                  ),

                  // Conversation history
                  _buildPracticeCard(
                    context: context,
                    title: 'History',
                    icon: Icons.history,
                    color: Colors.purple,
                    description: 'Review your past practice sessions',
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.historyList);
                    },
                  ),

                  // Free conversation
                  _buildPracticeCard(
                    context: context,
                    title: 'Free Conversation',
                    icon: Icons.chat,
                    color: Colors.orange,
                    description: 'Practice English in an open-ended conversation',
                    onTap: () {
                      _startFreeConversation(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startFreeConversation(BuildContext context) {
    // This would create a new conversation and navigate to it
    // For now, we'll just show a dialog as a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Free Conversation'),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}