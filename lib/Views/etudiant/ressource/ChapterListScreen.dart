import 'package:flutter/material.dart';
import 'package:primeprof/Views/etudiant/ressource/DetailsCourse.dart';
import 'package:primeprof/models/chapter.dart';
import 'package:primeprof/models/fiche.dart';

class ChapterListScreen extends StatefulWidget {
  final String subjectName;
  final List<Chapter> chapters;

  const ChapterListScreen({
    Key? key,
    required this.subjectName,
    required this.chapters,
  }) : super(key: key);

  @override
  _ChapterListScreenState createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme here
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subjectName,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: theme.colorScheme.onPrimary, // Use onPrimary for contrast
          ),
        ),
        backgroundColor: theme.colorScheme.primary, // Use primary color
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // Theme-aware background
        ),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: ListView.builder(
            itemCount: widget.chapters.length,
            itemBuilder: (context, index) {
              final chapter = widget.chapters[index];
              final chapterTitle = chapter.title;
              final fiches = chapter.fiches ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    color: theme.colorScheme.surface, // Use surface for card
                    child: Container(
                      width: double.infinity,
                      height: 80,
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
                            color: theme.shadowColor.withOpacity(0.2), // Theme-aware shadow
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          chapterTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary, // Contrast with gradient
                            fontFamily: 'Georgia',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (fiches.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Text(
                        'Aucune fiche disponible pour ce chapitre.',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.6), // Subtle text
                          fontFamily: 'Georgia',
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: fiches.map((fiche) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailsCourse(
                                      courseTitle: fiche.title,
                                      chapterTitle: chapterTitle,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                color: theme.colorScheme.surface, // Theme-aware card color
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.shadowColor.withOpacity(0.1), // Subtle shadow
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    fiche.title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: theme.colorScheme.primary, // Use primary for emphasis
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Georgia',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}