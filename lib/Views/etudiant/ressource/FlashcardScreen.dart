import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:primeprof/services/api_service.dart';
import 'package:primeprof/view_models/resource_viewmodel.dart';
import 'dart:developer' as developer;

class FlashcardScreen extends StatefulWidget {
  final String courseTitle;
  final String chapterTitle;

  const FlashcardScreen({
    Key? key,
    required this.courseTitle,
    required this.chapterTitle,
  }) : super(key: key);

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _learnedCount = 0;
  int _knewCount = 0;
  List<Map<String, String>> flashcards = [];
  bool isLoading = true;
  String? errorMessage;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchFlashcards();
  }

  Future<void> _fetchFlashcards() async {
    try {
      final viewModel = Provider.of<ResourceViewModel>(context, listen: false);
      final fiche = viewModel.getFicheForCourseAndChapter(
          widget.courseTitle, widget.chapterTitle);
      if (fiche == null) {
        developer.log(
            'Aucune fiche trouvée pour ${widget.courseTitle} - ${widget.chapterTitle}');
        setState(() {
          errorMessage = 'Aucune fiche trouvée pour ce cours et ce chapitre.';
          isLoading = false;
        });
        return;
      }
      final chapterId = fiche.chapter!['id'] as String;
      developer.log('Récupération des flashcards pour chapterId : $chapterId');

      final flashcardData =
          await apiService.getFlashcardsByChapterId(chapterId);
      developer.log('Données des flashcards reçues : $flashcardData');

      setState(() {
        flashcards = flashcardData
            .map((item) => {
                  'question': item['question'] as String,
                  'answer': item['answer'] as String,
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      developer.log('Erreur lors de la récupération des flashcards : $e');
      setState(() {
        errorMessage = 'Erreur lors du chargement des flashcards : $e';
        isLoading = false;
      });
    }
  }

  void _toggleCard() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _nextFlashcard(String feedbackType) {
    setState(() {
      _showAnswer = false;
      if (feedbackType == 'learned') _learnedCount++;
      if (feedbackType == 'knew') _knewCount++;
      _currentIndex = (_currentIndex + 1) % flashcards.length;

      if (_currentIndex == 0 && _learnedCount + _knewCount > 0) {
        _showSummary();
      }
    });
  }

  void _showSummary() {
    final theme = Theme.of(context); // Access theme in dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: EdgeInsets.all(20),
          backgroundColor: Colors.transparent,
          content: Container(
            width: 380,
            height: 480,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.onPrimary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    child: Center(
                      child: Text(
                        'Résultats',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                          fontFamily: 'Georgia',
                          shadows: [
                            Shadow(
                              color: theme.shadowColor.withOpacity(0.2),
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'J\'ai appris quelque chose !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red[300]!,
                              Colors.red[600]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_learnedCount',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.close, size: 40, color: Colors.white),
                          ],
                        ),
                      ),
                      SizedBox(width: 40),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[300]!,
                              Colors.green[600]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_knewCount',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.check, size: 40, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _showAnswer = false;
                        _learnedCount = 0;
                        _knewCount = 0;
                      });
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                      elevation: 8,
                    ),
                    child: Text(
                      'Recommencer',
                      style: TextStyle(
                        fontSize: 22,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: theme.shadowColor.withOpacity(0.2),
                            offset: Offset(1, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme here
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.courseTitle} - ${widget.chapterTitle}'),
          backgroundColor: theme.colorScheme.primary,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.courseTitle} - ${widget.chapterTitle}'),
          backgroundColor: theme.colorScheme.primary,
        ),
        body: Center(
          child: Text(
            errorMessage!,
            style: TextStyle(fontSize: 18, color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.courseTitle} - ${widget.chapterTitle}'),
          backgroundColor: theme.colorScheme.primary,
        ),
        body: Center(
          child: Text(
            'Aucune flashcard disponible pour ce chapitre.',
            style:
                TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
      );
    }

    final flashcard = flashcards[_currentIndex];
    final String textToShow =
        _showAnswer ? flashcard['answer']! : flashcard['question']!;
    final Gradient cardGradient = _showAnswer
        ? LinearGradient(
            colors: [Colors.orange[400]!, Colors.orange[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.courseTitle} - ${widget.chapterTitle}',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // Theme-aware background
        ),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _toggleCard,
                child: Card(
                  elevation: 15,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  color: theme.colorScheme.surface, // Theme-aware card color
                  child: Container(
                    width: double.infinity,
                    height: 450,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: cardGradient,
                              ),
                              child: CustomPaint(
                                painter: WavePainter(),
                                child: Center(
                                  child: Text(
                                    _showAnswer ? 'Réponse' : 'Question',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimary,
                                      fontFamily: 'Georgia',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 100, left: 20, right: 20, bottom: 20),
                            child: Text(
                              textToShow,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                                fontFamily: 'Georgia',
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(flashcards.length, (index) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 5),
                                width: _currentIndex == index ? 12 : 8,
                                height: _currentIndex == index ? 12 : 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentIndex == index
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _nextFlashcard('learned');
                    },
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.close, size: 35, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 30),
                  GestureDetector(
                    onTap: () {
                      _nextFlashcard('knew');
                    },
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.check, size: 35, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}