import 'package:flutter/material.dart';
import 'package:primeprof/Views/UserManagement/login_screen.dart';
import 'package:primeprof/Views/etudiant/List_chat.dart';
import 'package:primeprof/Views/etudiant/PaymentScreen.dart';
import 'package:primeprof/Views/etudiant/StudentScreen.dart';
import 'package:primeprof/Views/etudiant/TutorAIScreen.dart';
import 'package:primeprof/Views/etudiant/ressource/ChapterListScreen.dart';
import 'package:primeprof/Views/etudiant/student_drawer.dart';
import 'package:primeprof/view_models/resource_viewmodel.dart';
import 'package:provider/provider.dart';

class ResourceScreen extends StatefulWidget {
  @override
  _ResourceScreenState createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> levels = [
    'Première année primaire',
    'Deuxième année primaire',
    'Troisième année primaire',
    'Quatrième année primaire',
    'Cinquième année primaire',
    'Sixième année primaire',
  ];

  String selectedLevel = 'Première année primaire';
  int _selectedIndex = 2;

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EtudiantScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MessagesScreenE(name: 'Student Name')),
      );
    } else if (index == 4) {
      Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PaymentScreen()),
);
    } else if (index == 5) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TutorAIScreen(cameras: [])),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResourceScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme here
    return Consumer<ResourceViewModel>(
      builder: (context, viewModel, child) {
        viewModel.setSelectedLevel(selectedLevel);
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface, // Use surface color
            elevation: 6,
            title: Text(
              'Ressources',
              style: TextStyle(
                color: theme.colorScheme.primary, // Use primary color
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            leading: IconButton(
              icon: Icon(Icons.menu, color: theme.colorScheme.primary, size: 30),
              onPressed: () {
                _scaffoldKey.currentState!.openDrawer();
              },
            ),
          ),
          drawer: StudentDrawer(
            selectedIndex: _selectedIndex,
            onItemTapped: (index) => _onItemTapped(index, context),
          ),
          body: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor, // Use scaffold background
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Niveau d\'étude :',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface, // Text adapts to theme
                    ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface, // Use surface color
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.2), // Theme-aware shadow
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: selectedLevel,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLevel = newValue!;
                          viewModel.setSelectedLevel(selectedLevel);
                        });
                      },
                      items: levels.map<DropdownMenuItem<String>>((String level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(
                            level,
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onSurface, // Text adapts to theme
                              fontFamily: 'Georgia',
                            ),
                          ),
                        );
                      }).toList(),
                      underline: SizedBox(),
                      isExpanded: true,
                      style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface),
                      icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary, size: 30),
                      dropdownColor: theme.colorScheme.surface, // Dropdown background
                    ),
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: viewModel.isLoading
                        ? Center(child: CircularProgressIndicator())
                        : viewModel.error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Erreur : ${viewModel.error}',
                                      style: TextStyle(color: theme.colorScheme.onSurface),
                                    ),
                                    SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () => viewModel.refresh(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: TextStyle(color: theme.colorScheme.onPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1.3,
                                ),
                                itemCount: viewModel.getSubjectsForCurrentLevel().length,
                                itemBuilder: (context, index) {
                                  String subject = viewModel.getSubjectsForCurrentLevel()[index];
                                  IconData iconData = _getSubjectIcon(subject);

                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 8,
                                    color: theme.colorScheme.surface, // Card background
                                    child: InkWell(
                                      onTap: () async {
                                        try {
                                          final chapters = await viewModel.getChaptersForSubject(subject);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChapterListScreen(
                                                subjectName: viewModel.getSubjectDisplayName(subject),
                                                chapters: chapters,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Erreur : $e')),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.primary.withOpacity(0.7),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.shadowColor.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              iconData,
                                              color: theme.colorScheme.onPrimary, // Icon color
                                              size: 60,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              viewModel.getSubjectDisplayName(subject),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onPrimary, // Text color
                                                fontFamily: 'Georgia',
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'maths':
        return Icons.functions;
      case 'français':
        return Icons.language;
      case 'svt':
        return Icons.science;
      case 'anglais':
        return Icons.translate;
      case 'histoire':
        return Icons.history;
      case 'géographie':
        return Icons.map;
      case 'éducation civique':
        return Icons.school;
      case 'arts plastiques':
        return Icons.brush;
      case 'physique':
        return Icons.lightbulb_outline;
      default:
        return Icons.help_outline;
    }
  }
}