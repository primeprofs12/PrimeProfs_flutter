import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({Key? key}) : super(key: key);

  @override
  _QuizHistoryScreenState createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  List<Map<String, dynamic>> _quizResults = [];

  @override
  void initState() {
    super.initState();
    _loadQuizResults();
  }

  Future<void> _loadQuizResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = prefs.getStringList('quiz_results') ?? [];
      setState(() {
        _quizResults = results
            .map((result) => jsonDecode(result) as Map<String, dynamic>)
            .toList();
      });
      developer.log('Loaded quiz results: $_quizResults');
    } catch (e) {
      developer.log('Error loading quiz results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des résultats : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme here
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historique des Quiz',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary, // Use primary color
        foregroundColor: theme.colorScheme.onPrimary, // Text/icon color
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // Theme-aware background
        ),
        child: _quizResults.isEmpty
            ? Center(
                child: Text(
                  'Aucun résultat de quiz trouvé.',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _quizResults.length,
                itemBuilder: (context, index) {
                  final result = _quizResults[index];
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: theme.colorScheme.surface, // Theme-aware card color
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${result['courseTitle']} - ${result['chapterTitle']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary, // Emphasis color
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Score: ${result['score']}/${result['total']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${result['date']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Réponses: ${result['answers'].join(', ')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}