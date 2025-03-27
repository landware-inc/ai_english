// lib/screens/scenario/scenario_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/scenario_model.dart';
import '../../providers/scenario_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../routes.dart';
import '../../widgets/loading_indicator.dart';

class ScenarioDetailScreen extends StatefulWidget {
  final String scenarioId;

  const ScenarioDetailScreen({
    Key? key,
    required this.scenarioId,
  }) : super(key: key);

  @override
  State<ScenarioDetailScreen> createState() => _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState extends State<ScenarioDetailScreen> {
  final _uuid = Uuid();

  // Selected options
  String? _selectedRole;
  final List<String> _selectedKeywords = [];
  final List<String> _practicePhrasesAdded = [];

  // Text controller for custom phrases
  final TextEditingController _phraseController = TextEditingController();

  // Loading state
  bool _isCreatingSession = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Set the current scenario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);
      scenarioProvider.setCurrentScenario(widget.scenarioId);
    });
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Scenario'),
      ),
      body: Consumer<ScenarioProvider>(
        builder: (context, scenarioProvider, child) {
          if (scenarioProvider.isLoading) {
            return const LoadingIndicator(message: 'Loading scenario...');
          }

          final scenario = scenarioProvider.currentScenario;

          if (scenario == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error: Scenario not found',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return _buildScenarioForm(context, scenario);
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildScenarioForm(BuildContext context, Scenario scenario) {
    // Initialize selected role if not already set
    _selectedRole ??= scenario.roles.isNotEmpty ? scenario.roles.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scenario header
          _buildScenarioHeader(scenario),

          const SizedBox(height: 24),

          // Role selection
          _buildSection(
            title: 'Select Your Role',
            child: _buildRoleSelection(scenario.roles),
          ),

          const SizedBox(height: 24),

          // Keywords selection
          _buildSection(
            title: 'Select Keywords',
            subtitle: 'Choose keywords to focus the conversation (select up to 3)',
            child: _buildKeywordSelection(scenario.suggestedKeywords),
          ),

          const SizedBox(height: 24),

          // Practice phrases
          _buildSection(
            title: 'Add Practice Phrases',
            subtitle: 'Add phrases you want to practice in this conversation',
            child: _buildPracticePhrasesSection(scenario.suggestedPhrases),
          ),

          // Show error if any
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Extra space at bottom for scrolling
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildScenarioHeader(Scenario scenario) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scenario.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scenario.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDifficultyIndicator(scenario.difficultyLevel),
                const SizedBox(width: 8),
                if (scenario.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildRoleSelection(List<String> roles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: roles.map((role) {
            return RadioListTile<String>(
              title: Text(role),
              value: role,
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKeywordSelection(List<String> keywords) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.map((keyword) {
            final isSelected = _selectedKeywords.contains(keyword);
            return FilterChip(
              label: Text(keyword),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected && _selectedKeywords.length < 3) {
                    _selectedKeywords.add(keyword);
                  } else if (!selected) {
                    _selectedKeywords.remove(keyword);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPracticePhrasesSection(List<String> suggestedPhrases) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add new practice phrase section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phraseController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a phrase to practice',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addPracticePhrase(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPracticePhrase,
                  child: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Suggested phrases heading
            if (suggestedPhrases.isNotEmpty)
              const Text(
                'Suggested Phrases:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

            // Suggested phrases
            if (suggestedPhrases.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestedPhrases.map((phrase) {
                    final isAdded = _practicePhrasesAdded.contains(phrase);
                    return ActionChip(
                      label: Text(phrase),
                      backgroundColor: isAdded ? Colors.blue.shade100 : null,
                      labelStyle: TextStyle(
                        color: isAdded ? Colors.blue.shade800 : null,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isAdded) {
                            _practicePhrasesAdded.remove(phrase);
                          } else {
                            _practicePhrasesAdded.add(phrase);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

            // Added phrases heading
            if (_practicePhrasesAdded.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Text(
                      'Your Practice Phrases:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _practicePhrasesAdded.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

            // Display added phrases
            if (_practicePhrasesAdded.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _practicePhrasesAdded.map((phrase) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(phrase),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                            onPressed: () {
                              setState(() {
                                _practicePhrasesAdded.remove(phrase);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isCreatingSession ? null : _startScenarioSession,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isCreatingSession
              ? const CircularProgressIndicator()
              : const Text(
            'Start Conversation',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  void _addPracticePhrase() {
    final phrase = _phraseController.text.trim();
    if (phrase.isNotEmpty) {
      setState(() {
        if (!_practicePhrasesAdded.contains(phrase)) {
          _practicePhrasesAdded.add(phrase);
        }
        _phraseController.clear();
      });
    }
  }

  Future<void> _startScenarioSession() async {
    if (_selectedRole == null) {
      setState(() {
        _error = 'Please select a role';
      });
      return;
    }

    setState(() {
      _isCreatingSession = true;
      _error = null;
    });

    try {
      // Create a new conversation
      final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
      final scenarioProvider = Provider.of<ScenarioProvider>(context, listen: false);

      // Create a conversation first
      final conversationTitle = '${scenarioProvider.currentScenario!.name} - $_selectedRole';
      conversationProvider.createScenarioConversation(
        scenarioId: widget.scenarioId,
        title: conversationTitle,
      );

      final conversationId = conversationProvider.currentConversation!.id;

      // Create the scenario session
      final session = await scenarioProvider.createSession(
        scenarioId: widget.scenarioId,
        selectedRole: _selectedRole!,
        selectedKeywords: _selectedKeywords,
        practicePhrasesAdded: _practicePhrasesAdded,
        conversationId: conversationId,
      );

      if (session != null) {
        if (!mounted) return;

        // Navigate to the chat screen
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.scenarioChat,
          arguments: {
            'sessionId': session.id,
            'conversationId': conversationId,
          },
        );
      } else {
        setState(() {
          _error = 'Failed to create session';
          _isCreatingSession = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isCreatingSession = false;
      });
    }
  }

  Widget _buildDifficultyIndicator(int level) {
    Color color;
    String text;

    switch (level) {
      case 1:
        color = Colors.green;
        text = 'Beginner';
        break;
      case 2:
        color = Colors.lightGreen;
        text = 'Elementary';
        break;
      case 3:
        color = Colors.orange;
        text = 'Intermediate';
        break;
      case 4:
        color = Colors.deepOrange;
        text = 'Advanced';
        break;
      case 5:
        color = Colors.red;
        text = 'Expert';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}