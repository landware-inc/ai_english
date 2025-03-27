// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';
import 'services/claude_service.dart';
import 'services/storage_service.dart';
import 'services/speech_service.dart';
import 'providers/conversation_provider.dart';
import 'providers/qa_provider.dart';
import 'providers/scenario_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  // Get API key from environment variables
  final apiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    print('WARNING: CLAUDE_API_KEY not found in .env file');
  }

  runApp(MyApp(
    apiKey: apiKey,
    storageService: storageService,
  ));
}

class MyApp extends StatelessWidget {
  final String apiKey;
  final StorageService storageService;

  const MyApp({
    Key? key,
    required this.apiKey,
    required this.storageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<ClaudeService>(
          create: (_) => ClaudeService(apiKey: apiKey),
        ),
        Provider<StorageService>.value(
          value: storageService,
        ),
        Provider<SpeechService>(
          create: (_) => SpeechService(),
          dispose: (_, service) => service.dispose(),
        ),

        // State providers
        ChangeNotifierProvider<ConversationProvider>(
          create: (context) => ConversationProvider(
            claudeService: context.read<ClaudeService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider<QAProvider>(
          create: (context) => QAProvider(
            claudeService: context.read<ClaudeService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider<ScenarioProvider>(
          create: (context) => ScenarioProvider(
            storageService: context.read<StorageService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AI English Practice',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}