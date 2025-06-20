import 'package:flutter/material.dart';
import 'package:primeprof/view_models/resource_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuizScreen extends StatefulWidget {
  final String courseTitle;
  final String chapterTitle;

  const QuizScreen({
    Key? key,
    required this.courseTitle,
    required this.chapterTitle,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  List<int?> _userAnswers = [];
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    final viewModel = Provider.of<ResourceViewModel>(context, listen: false);
    try {
      developer.log(
          'Starting to load quiz data for ${widget.courseTitle} - ${widget.chapterTitle}');
      final fiche = viewModel.getFicheForCourseAndChapter(
          widget.courseTitle, widget.chapterTitle);
      if (fiche == null || fiche.chapter == null) {
        developer.log(
            'No fiche or chapter found for ${widget.courseTitle} - ${widget.chapterTitle}');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Aucune fiche ou chapitre trouvé.';
        });
        return;
      }
      final chapterId = fiche.chapter!['id'] as String;
      developer.log('Fetching quizzes for chapterId: $chapterId');
      final quizzes = await viewModel.getQuizzesByChapterId(chapterId);
      developer.log('Received quizzes: $quizzes');

      if (quizzes.isEmpty) {
        developer.log('No quizzes found for chapterId: $chapterId');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Aucun quiz disponible pour ce chapitre.';
        });
        return;
      }

      setState(() {
        _questions = quizzes.map((quiz) {
          developer.log('Processing quiz: $quiz');
          final questionText =
              quiz['question'] as String? ?? 'Question non définie';
          final optionsString = quiz['options'] as String? ?? '';
          final options = optionsString.isNotEmpty
              ? optionsString.split(',')
              : ['Aucune option disponible'];
          final correctAnswer = quiz['correctAnswer'] as String? ?? '';
          final correctAnswerIndex = options.indexOf(correctAnswer);
          developer.log(
              'Options for quiz $questionText: $options, Correct Answer: $correctAnswer (index: $correctAnswerIndex)');
          return {
            'question': questionText,
            'options': options,
            'correctAnswer': correctAnswerIndex >= 0 ? correctAnswerIndex : 0,
            'correctAnswerText': correctAnswer,
          };
        }).toList();
        if (_questions.isEmpty) {
          developer.log('No quizzes after mapping');
          _errorMessage = 'Aucun quiz valide trouvé.';
        } else {
          _userAnswers = List.filled(_questions.length, null);
        }
        _isLoading = false;
      });
      developer.log(
          'Loaded ${_questions.length} quiz questions for chapter $chapterId');
    } catch (e) {
      developer.log('Error loading quiz data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement du quiz : $e';
      });
    }
  }

  Future<void> _saveQuizResult(int score, int total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = prefs.getStringList('quiz_results') ?? [];
      final result = {
        'courseTitle': widget.courseTitle,
        'chapterTitle': widget.chapterTitle,
        'score': score.toString(),
        'total': total.toString(),
        'date': DateTime.now().toIso8601String(),
        'answers':
            _userAnswers.map((answer) => answer?.toString() ?? 'null').toList(),
      };
      results.add(jsonEncode(result));
      await prefs.setStringList('quiz_results', results);
      developer.log('Quiz result saved locally: $result');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Résultat du quiz sauvegardé localement')),
      );
    } catch (e) {
      developer.log('Error saving quiz result locally: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erreur lors de l’enregistrement local du résultat : $e')),
      );
    }
  }

  void _nextQuestion() {
    setState(() {
      if (_selectedAnswer != null) {
        _userAnswers[_currentQuestionIndex] = _selectedAnswer;
      }
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
      }
    });
  }

  void _submitQuiz() {
    if (_selectedAnswer != null) {
      _userAnswers[_currentQuestionIndex] = _selectedAnswer;
    }

    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['correctAnswer']) {
        correctAnswers++;
      }
    }

    _saveQuizResult(correctAnswers, _questions.length);

    final theme = Theme.of(context); // Access theme in dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface, // Theme-aware background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Résultat du Quiz',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Score : $correctAnswers / ${_questions.length}',
                style: TextStyle(fontSize: 20, color: theme.colorScheme.onPrimary),
              ),
            ],
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récapitulatif des réponses :',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                ..._questions.asMap().entries.map((entry) {
                  int idx = entry.key;
                  final question = entry.value;
                  final options = question['options'] as List<dynamic>;
                  final userAnswerIndex = _userAnswers[idx];
                  final userAnswer = userAnswerIndex != null
                      ? options[userAnswerIndex]
                      : 'Non répondu';
                  final correctAnswerIndex = question['correctAnswer'] as int;
                  final correctAnswer = question['correctAnswerText'] as String;
                  final isCorrect = userAnswerIndex == correctAnswerIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${idx + 1}: ${question['question']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Votre réponse : $userAnswer',
                          style: TextStyle(
                            fontSize: 14,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          'Réponse correcte : $correctAnswer',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Divider(color: theme.dividerColor),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 18, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme here
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz - ${widget.courseTitle}'),
          backgroundColor: theme.colorScheme.primary,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz - ${widget.courseTitle}'),
          backgroundColor: theme.colorScheme.primary,
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz - ${widget.courseTitle}'),
          backgroundColor: theme.colorScheme.primary,
        ),
        body: Center(
          child: Text(
            'Aucun quiz disponible pour ce chapitre.',
            style:
                TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final options = currentQuestion['options'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz - ${widget.courseTitle}',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor, // Theme-aware background
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.2),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  minHeight: 8,
                ),
                const SizedBox(height: 20),
                Text(
                  'Question ${_currentQuestionIndex + 1} / ${_questions.length}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: theme.colorScheme.surface, // Theme-aware card color
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQuestion['question'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...options.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String option = entry.value as String;
                          bool isSelected = _selectedAnswer == idx;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAnswer = idx;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : theme.colorScheme.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.dividerColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: idx,
                                    groupValue: _selectedAnswer,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAnswer = value;
                                      });
                                    },
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: theme.colorScheme.onSurface,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentQuestionIndex < _questions.length - 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed:
                              _selectedAnswer == null ? null : _nextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                          ),
                          child: Text(
                            'Suivant',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (_currentQuestionIndex == _questions.length - 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed:
                              _selectedAnswer == null ? null : _submitQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                          ),
                          child: Text(
                            'Envoyer',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}