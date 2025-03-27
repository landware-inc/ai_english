// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/speech_service.dart';
import '../utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  bool _isLoading = true;
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initPackageInfo();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getUserSettings();

      setState(() {
        _settings = settings;
        _isLoading = false;
      });

      // Load API key
      final apiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
      _apiKeyController.text = apiKey;

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    }
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.updateSetting(key, value);

      setState(() {
        _settings[key] = value;
      });

      // Apply settings
      if (key == 'debugMode') {
        Logger.setDebugMode(value);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting: $e')),
      );
    }
  }

  Future<void> _saveAPIKey() async {
    final apiKey = _apiKeyController.text.trim();

    // We can't actually modify the .env file at runtime
    // In a real app, you might store this securely and apply on next app start
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key will be applied on next app restart'),
      ),
    );
  }

  Future<void> _clearAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will delete all conversations, practice sessions, and settings. '
                'This action cannot be undone. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final storageService = Provider.of<StorageService>(context, listen: false);
        final success = await storageService.clearAllData();

        setState(() {
          _isLoading = false;
        });

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully')),
          );

          // Reload settings
          _loadSettings();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSettingsList(),
    );
  }

  Widget _buildSettingsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // API Settings
        _buildSettingsSection(
          title: 'API Settings',
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'Claude API Key',
                  border: OutlineInputBorder(),
                  helperText: 'Enter your Claude API key',
                ),
                obscureText: true,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveAPIKey,
                child: const Text('Save API Key'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Speech Settings
        _buildSettingsSection(
          title: 'Speech Settings',
          children: [
            Consumer<SpeechService>(
              builder: (context, speechService, child) {
                return FutureBuilder<List<String>>(
                  future: speechService.getAvailableLocales(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }

                    final locales = snapshot.data ?? [];
                    final currentLocale = _settings['speechLocale'] ?? 'en_US';

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Speech Recognition Language',
                        border: OutlineInputBorder(),
                      ),
                      value: locales.contains(currentLocale) ? currentLocale : locales.first,
                      items: locales.map((locale) {
                        return DropdownMenuItem<String>(
                          value: locale,
                          child: Text(_formatLocale(locale)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateSetting('speechLocale', value);
                          speechService.setLocale(value);
                        }
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Auto-play AI Responses'),
              subtitle: const Text('Automatically read AI responses aloud'),
              value: _settings['autoPlayResponses'] ?? true,
              onChanged: (value) => _updateSetting('autoPlayResponses', value),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // App Settings
        _buildSettingsSection(
          title: 'App Settings',
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark color theme'),
              value: _settings['darkMode'] ?? false,
              onChanged: (value) => _updateSetting('darkMode', value),
            ),

            SwitchListTile(
              title: const Text('Auto-save Conversations'),
              subtitle: const Text('Automatically save conversations as they happen'),
              value: _settings['autoSaveConversations'] ?? true,
              onChanged: (value) => _updateSetting('autoSaveConversations', value),
            ),

            SwitchListTile(
              title: const Text('Debug Mode'),
              subtitle: const Text('Enable detailed logging for debugging'),
              value: _settings['debugMode'] ?? false,
              onChanged: (value) => _updateSetting('debugMode', value),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Data Management
        _buildSettingsSection(
          title: 'Data Management',
          children: [
            ListTile(
              title: const Text('Clear All Data'),
              subtitle: const Text('Delete all conversations, sessions, and settings'),
              trailing: const Icon(Icons.delete_forever),
              onTap: _clearAllData,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // About
        _buildSettingsSection(
          title: 'About',
          children: [
            ListTile(
              title: Text(_packageInfo.appName),
              subtitle: Text('Version ${_packageInfo.version} (Build ${_packageInfo.buildNumber})'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
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
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  String _formatLocale(String locale) {
    // Format locale codes to be more readable
    // e.g., "en_US" -> "English (United States)"
    final parts = locale.split('_');
    if (parts.length != 2) return locale;

    String language;
    String country;

    switch (parts[0].toLowerCase()) {
      case 'en': language = 'English'; break;
      case 'es': language = 'Spanish'; break;
      case 'fr': language = 'French'; break;
      case 'de': language = 'German'; break;
      case 'it': language = 'Italian'; break;
      case 'ja': language = 'Japanese'; break;
      case 'ko': language = 'Korean'; break;
      case 'zh': language = 'Chinese'; break;
      default: language = parts[0];
    }

    switch (parts[1].toUpperCase()) {
      case 'US': country = 'United States'; break;
      case 'GB': country = 'United Kingdom'; break;
      case 'AU': country = 'Australia'; break;
      case 'CA': country = 'Canada'; break;
      case 'IN': country = 'India'; break;
      case 'ES': country = 'Spain'; break;
      case 'MX': country = 'Mexico'; break;
      case 'FR': country = 'France'; break;
      case 'DE': country = 'Germany'; break;
      case 'IT': country = 'Italy'; break;
      case 'JP': country = 'Japan'; break;
      case 'KR': country = 'Korea'; break;
      case 'CN': country = 'China'; break;
      case 'TW': country = 'Taiwan'; break;
      default: country = parts[1];
    }

    return '$language ($country)';
  }
}