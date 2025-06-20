import 'package:primeprof/models/fiche.dart';
import 'dart:developer' as developer;

class Chapter {
  final String id;
  final String title;
  final String studyLevel;
  final String academicClass;
  final String subject;
  final List<Fiche>? fiches;

  Chapter({
    required this.id,
    required this.title,
    required this.studyLevel,
    required this.academicClass,
    required this.subject,
    this.fiches,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      developer.log('Erreur : JSON est null');
      throw Exception('JSON est null');
    }

    developer.log('Parsing chapter from JSON: $json');

    return Chapter(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sans titre',
      studyLevel: json['studyLevel'] as String? ?? '',
      academicClass: json['academicClass'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      fiches: json['fiches'] != null
          ? (json['fiches'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((f) => Fiche.fromJson(f))
              .toList()
          : null,
    );
  }
}
