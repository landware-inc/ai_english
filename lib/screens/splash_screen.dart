// lib/screens/splash_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../providers/qa_provider.dart';
import '../utils/citizenship_parser.dart';
import '../utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late String _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _statusMessage = 'Initializing...';

    // Initialize the app on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _statusMessage = 'Loading citizenship questions...';
      });

      // Process the US citizenship questions if needed
      await _processCitizenshipQuestions();

      setState(() {
        _statusMessage = 'Ready!';
      });

      // Navigate to home screen after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing: $e';
        _isError = true;
      });

      Logger.error('Initialization error: $e');
    }
  }

  // Future<void> _processCitizenshipQuestions() async {
  //   try {
  //     // Get the QA provider
  //     final qaProvider = Provider.of<QAProvider>(context, listen: false);
  //
  //     // Check if US citizenship questions already exist
  //     final datasets = await qaProvider.getAllQASets();
  //
  //     if (!datasets.contains('us_citizenship_questions')) {
  //       // Load the PDF content from assets
  //       final pdfContent = await rootBundle.loadString('assets/qa_data/US_Citizenship_100q.txt');
  //
  //       // Parse the PDF content
  //       final jsonContent = await CitizenshipParser.parseUSCitizenshipQuestions(pdfContent);
  //
  //       // Save the parsed content
  //       await qaProvider.processUSCitizenshipQuestions(jsonContent);
  //       Logger.debug('${qaProvider.totalQuestions} QA sets loaded');
  //       Logger.debug('Processed US citizenship questions ($datasets)');
  //     } else {
  //       Logger.debug('US citizenship questions already exist ($datasets)');
  //     }
  //   } catch (e) {
  //     Logger.error('Failed to process citizenship questions: $e');
  //     throw Exception('Failed to process citizenship questions: $e');
  //   }
  // }
  Future<void> _processCitizenshipQuestions() async {
    try {
      // Get the QA provider
      final qaProvider = Provider.of<QAProvider>(context, listen: false);

      // 항상 새로 처리하도록 수정
      // Load the PDF content from assets
      final pdfContent = await rootBundle.loadString('assets/qa_data/US_Citizenship_100q.txt');

      // Parse the PDF content
      final jsonContent = await CitizenshipParser.parseUSCitizenshipQuestions(pdfContent);

      // Save the parsed content
      await qaProvider.processUSCitizenshipQuestions(jsonContent);
      Logger.debug('${qaProvider.totalQuestions} QA sets loaded');
      Logger.debug('Processed US citizenship questions');
    } catch (e) {
      Logger.error('Failed to process citizenship questions: $e');
      throw Exception('Failed to process citizenship questions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                const Icon(
                  Icons.language,
                  size: 120,
                  color: Colors.white,
                ),

                const SizedBox(height: 24),

                // App name
                const Text(
                  'AI English Practice',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // App tagline
                const Text(
                  'Improve your English with AI-powered conversations',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Loading indicator
                if (!_isError)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),

                const SizedBox(height: 24),

                // Status message
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: _isError ? Colors.red.shade300 : Colors.white,
                  ),
                ),

                // Error retry button
                if (_isError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isError = false;
                          _statusMessage = 'Retrying...';
                        });
                        _initializeApp();
                      },
                      child: const Text('Retry'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}