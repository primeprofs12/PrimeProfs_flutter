import 'package:flutter/material.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  _ConsultationScreenState createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  List<Map<String, String>> courses = [
    {"time": "13h", "date": "Wed, 29 jan 2025", "duration": "2h"},
    {"time": "15h", "date": "Wed, 29 jan 2025", "duration": "2h"},
    {"time": "17h", "date": "Wed, 29 jan 2025", "duration": "2h"},
  ];

  Set<int> selectedCourses = {}; // Indices des cours sélectionnés

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme here
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          "Accepter un cours",
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor, // Theme-aware background
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar et Nom du professeur
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/img.png'), // Replace with real image
              backgroundColor: theme.colorScheme.onSurface, // Fallback color
            ),
            SizedBox(height: 10),
            Text(
              "Smith Mathew",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20),

            // Liste des horaires
            Column(
              children: List.generate(
                courses.length,
                (index) => _buildCourseTime(index),
              ),
            ),

            SizedBox(height: 220),

            // Bouton "Refuser le cours"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    courses = courses.asMap().entries
                        .where((entry) => !selectedCourses.contains(entry.key))
                        .map((entry) => entry.value)
                        .toList();
                    selectedCourses.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error, // Use error color for "cancel"
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Annuler le cours",
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher un horaire
  Widget _buildCourseTime(int index) {
    final theme = Theme.of(context);
    bool isSelected = selectedCourses.contains(index);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCourses.remove(index);
          } else {
            selectedCourses.add(index);
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeBox(courses[index]["time"]!),
            Text(
              courses[index]["date"]!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            _buildTimeBox(courses[index]["duration"]!),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher une boîte de temps
  Widget _buildTimeBox(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}