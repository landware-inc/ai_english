// lib/screens/scenario/scenario_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/scenario_provider.dart';
import '../../models/scenario_model.dart';
import '../../routes.dart';
import '../../widgets/loading_indicator.dart';

class ScenarioListScreen extends StatelessWidget {
  const ScenarioListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario Practice'),
      ),
      body: Consumer<ScenarioProvider>(
        builder: (context, scenarioProvider, child) {
          if (scenarioProvider.isLoading) {
            return const LoadingIndicator(message: 'Loading scenarios...');
          }

          if (scenarioProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${scenarioProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      scenarioProvider.clearError();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final categories = scenarioProvider.categories;

          if (categories.isEmpty) {
            return const Center(
              child: Text('No scenarios available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategorySection(context, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, ScenarioCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.name),
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.scenarios.length,
              itemBuilder: (context, index) {
                final scenario = category.scenarios[index];
                return _buildScenarioItem(context, scenario);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioItem(BuildContext context, Scenario scenario) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(
        scenario.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(scenario.description),
          const SizedBox(height: 4),
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
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.scenarioDetail,
          arguments: {'scenarioId': scenario.id},
        );
      },
    );
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

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'daily life':
        return Icons.home;
      case 'professional':
        return Icons.business;
      case 'travel':
        return Icons.flight;
      case 'emergency':
        return Icons.emergency;
      case 'citizenship':
        return Icons.gavel;
      default:
        return Icons.category;
    }
  }
}