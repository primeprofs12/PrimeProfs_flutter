import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:primeprof/Views/etudiant/ressource/QuizScreen.dart';
import 'package:primeprof/Views/etudiant/ressource/FlashcardScreen.dart';
import 'package:primeprof/view_models/resource_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class DetailsCourse extends StatefulWidget {
  final String courseTitle;
  final String chapterTitle;

  const DetailsCourse({
    Key? key,
    required this.courseTitle,
    required this.chapterTitle,
  }) : super(key: key);

  @override
  _DetailsCourseState createState() => _DetailsCourseState();
}

class _DetailsCourseState extends State<DetailsCourse> {
  int _selectedIndex = 0;
  int _currentExerciseIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  final Map<String, bool> _isCorrect = {};
  List<Map<String, dynamic>> _exercises = [];

  final List<Map<String, dynamic>> resourceTypes = [
    {'title': 'Cours', 'icon': Icons.library_books},
    {'title': 'Exercices', 'icon': Icons.checklist},
    {'title': 'Quiz', 'icon': Icons.help_outline},
    {'title': 'Flashcards', 'icon': Icons.view_carousel},
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final viewModel = Provider.of<ResourceViewModel>(context, listen: false);
    final exercises = await _fetchExerciseContent(viewModel);
    setState(() {
      _exercises = exercises;
      _currentExerciseIndex = 0;
      _selectedAnswers.clear();
      _isCorrect.clear();
    });
  }

  Future<String?> _fetchCourseContent(ResourceViewModel viewModel) async {
    try {
      final fiche = viewModel.getFicheForCourseAndChapter(
          widget.courseTitle, widget.chapterTitle);
      if (fiche == null) {
        developer.log(
            'No fiche found for ${widget.courseTitle} - ${widget.chapterTitle}');
        return null;
      }
      developer
          .log('Fetched attachment for ${fiche.title}: ${fiche.attachment}');
      if (fiche.attachment.isNotEmpty) {
        developer.log('Attempting to download PDF from: ${fiche.attachment}');
        return await _downloadPdf(fiche.attachment);
      }
      developer.log('No attachment available for fiche ${fiche.title}');
      return null;
    } catch (e) {
      developer.log('Error in _fetchCourseContent: $e');
      return null;
    }
  }

  Future<String> _downloadPdf(String url) async {
    try {
      String downloadUrl = url;
      if (url.contains('drive.google.com')) {
        final fileIdMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
        if (fileIdMatch != null) {
          final fileId = fileIdMatch.group(1);
          downloadUrl =
              'https://drive.google.com/uc?export=download&id=$fileId';
          developer.log('Converted Google Drive URL to: $downloadUrl');
        } else {
          throw Exception(
              'Impossible d’extraire l’ID du fichier Google Drive depuis : $url');
        }
      }

      final client = http.Client();
      final response = await client
          .get(Uri.parse(downloadUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/course.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        developer
            .log('PDF downloaded successfully from $downloadUrl to $filePath');
        client.close();
        return filePath;
      } else {
        throw Exception(
            'Échec du téléchargement du PDF : ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error downloading PDF: $e');
      throw Exception('Erreur lors du téléchargement : $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExerciseContent(
      ResourceViewModel viewModel) async {
    try {
      final fiche = viewModel.getFicheForCourseAndChapter(
          widget.courseTitle, widget.chapterTitle);
      if (fiche == null || fiche.chapter == null) {
        developer.log(
            'No fiche or chapter found for ${widget.courseTitle} - ${widget.chapterTitle}');
        return [];
      }
      final chapterId = fiche.chapter!['id'] as String;
      final exercises = await viewModel.getExercisesByChapterId(chapterId);
      developer.log('Fetched exercises for chapter $chapterId: $exercises');
      return exercises;
    } catch (e) {
      developer.log('Error fetching exercises: $e');
      return [];
    }
  }

  void _checkAnswers(Map<String, dynamic> exercise) {
    setState(() {
      for (var question in exercise['questions']) {
        final questionId = question['questionText'] as String;
        final userAnswer = _selectedAnswers[questionId] ?? '';
        final correctAnswer = question['correctAnswer'] as String;
        _isCorrect[questionId] = userAnswer == correctAnswer;
      }
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _selectedAnswers.clear();
        _isCorrect.clear();
      });
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _selectedAnswers.clear();
        _isCorrect.clear();
      });
    }
  }

  Map<String, Widget> getContent(
      String resourceType, ResourceViewModel viewModel) {
    final theme = Theme.of(context); // Access theme here
    return {
      'Cours': FutureBuilder<String?>(
        future: _fetchCourseContent(viewModel),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            developer.log('Error in Cours section: ${snapshot.error}');
            return Text(
              'Erreur lors du chargement du cours. Vérifiez votre connexion ou l’URL.',
              style: TextStyle(color: theme.colorScheme.error),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Text(
              'Aucun contenu disponible pour ${widget.courseTitle} - ${widget.chapterTitle}',
              style: TextStyle(color: theme.colorScheme.onSurface),
            );
          }
          final filePath = snapshot.data!;
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: PDFView(
              filePath: filePath,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              onError: (error) {
                developer.log('Erreur PDFView : $error');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Erreur lors du chargement du PDF : $error')),
                );
              },
            ),
          );
        },
      ),
      'Exercices': _exercises.isEmpty
          ? Center(
              child: Text(
                'Aucun exercice disponible.',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercice ${_currentExerciseIndex + 1}/${_exercises.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: theme.colorScheme.primary),
                            onPressed:
                                _currentExerciseIndex > 0 ? _previousExercise : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward,
                                color: theme.colorScheme.primary),
                            onPressed: _currentExerciseIndex < _exercises.length - 1
                                ? _nextExercise
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: theme.colorScheme.surface, // Theme-aware card color
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _exercises[_currentExerciseIndex]['enonce'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...(_exercises[_currentExerciseIndex]['questions']
                                  as List<dynamic>)
                              .map((question) {
                            final questionText =
                                question['questionText'] as String;
                            final options =
                                question['options'] as List<dynamic>;
                            final correctAnswer =
                                question['correctAnswer'] as String;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  questionText,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                ...options.map((option) {
                                  return RadioListTile<String>(
                                    title: Text(
                                      option as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Georgia',
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    value: option,
                                    groupValue: _selectedAnswers[questionText],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAnswers[questionText] = value!;
                                      });
                                    },
                                    activeColor: theme.colorScheme.primary,
                                  );
                                }).toList(),
                                if (_isCorrect[questionText] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      _isCorrect[questionText]!
                                          ? 'Correct ! 🎉'
                                          : 'Incorrect. La bonne réponse est : $correctAnswer',
                                      style: TextStyle(
                                        color: _isCorrect[questionText]!
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 16,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _checkAnswers(
                                  _exercises[_currentExerciseIndex]),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              child: Text(
                                'Vérifier',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Fiche ID: ${_exercises[_currentExerciseIndex]['ficheId'] ?? "Non défini"} | Chapitre ID: ${_exercises[_currentExerciseIndex]['chapterId']} | État: ${_exercises[_currentExerciseIndex]['etat'] ? "Actif" : "Inactif"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      'Quiz': Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  courseTitle: widget.courseTitle,
                  chapterTitle: widget.chapterTitle,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Lancer le Quiz',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      'Flashcards': Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlashcardScreen(
                  courseTitle: widget.courseTitle,
                  chapterTitle: widget.chapterTitle,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Lancer les Flashcards',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme here
    final viewModel = Provider.of<ResourceViewModel>(context);

    final contentMap =
        getContent(resourceTypes[_selectedIndex]['title'], viewModel);
    final content = contentMap[resourceTypes[_selectedIndex]['title']] ??
        Text(
          'Contenu non disponible',
          style: TextStyle(color: theme.colorScheme.onSurface),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.courseTitle} - ${widget.chapterTitle}',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary, // Use primary color
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor, // Theme-aware background
          ),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(10),
                  itemCount: resourceTypes.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: theme.colorScheme.surface, // Theme-aware card color
                          child: Container(
                            width: 120,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: _selectedIndex == index
                                  ? LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  resourceTypes[index]['icon'] as IconData,
                                  size: 40,
                                  color: _selectedIndex == index
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  resourceTypes[index]['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedIndex == index
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // Theme-aware content area
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }
}