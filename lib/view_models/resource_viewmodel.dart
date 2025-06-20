import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chapter.dart';
import '../models/fiche.dart';
import 'dart:developer' as developer;

class ResourceViewModel extends ChangeNotifier {
  final ApiService _apiService;

  List<Chapter> _chapters = [];
  List<Fiche> _fiches = [];
  bool _isLoading = false;
  String? _error;
  String _selectedLevel = 'Première année primaire';
  int _selectedIndex = 2;

  List<Chapter> get chapters => _chapters;
  List<Fiche> get fiches => _fiches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedLevel => _selectedLevel;
  int get selectedIndex => _selectedIndex;
  List<String> get levels => subjectsByLevel.keys.toList();

  static const Map<String, List<String>> subjectsByLevel = {
    'Première année primaire': ['Français', 'Math', 'Histoire Géo'],
    'Deuxième année primaire': ['Français', 'Math', 'Histoire Géo'],
    'Troisième année primaire': ['Français', 'Math', 'SVT', 'Histoire Géo'],
    'Quatrième année primaire': ['Français', 'Math', 'SVT', 'Anglais'],
    'Cinquième année primaire': [
      'Français',
      'Math',
      'SVT',
      'Anglais',
      'Physique'
    ],
    'Sixième': ['Français', 'Math', 'SVT', 'Anglais', 'Histoire Géo'],
    'Cinquième': [
      'Français',
      'Math',
      'SVT',
      'Anglais',
      'Histoire Géo',
      'Physique'
    ],
    'Quatrième': [
      'Français',
      'Math',
      'SVT',
      'Anglais',
      'Histoire Géo',
      'Physique'
    ],
    'Troisième': [
      'Français',
      'Math',
      'SVT',
      'Anglais',
      'Histoire Géo',
      'Physique',
      'Chimie'
    ],
    'Deuxième': [
      'Français',
      'Math',
      'SVT',
      'Anglais',
      'Histoire Géo',
      'Physique',
      'Chimie'
    ],
    'Première': [
      'Français',
      'Math',
      'SVT',
      'Anglais',
      'Histoire Géo',
      'Physique',
      'Chimie'
    ],
    'Terminale': [
      'Math',
      'SVT',
      'Anglais',
      'Histoire Géo',
      'Physique',
      'Chimie',
      'Philosophie'
    ],
  };

  static const Map<String, String> levelToAcademicClass = {
    'Première année primaire': 'CP',
    'Deuxième année primaire': 'CE1',
    'Troisième année primaire': 'CE2',
    'Quatrième année primaire': 'CM1',
    'Cinquième année primaire': 'CM2',
    'Sixième': 'SIXIEME',
    'Cinquième': 'CINQUIEME',
    'Quatrième': 'QUATRIEME',
    'Troisième': 'TROISIEME',
    'Deuxième': 'DEUXIEME',
    'Première': 'PREMIERE',
    'Terminale': 'TERMINALE',
  };

  static const Map<String, String> subjectDisplayNames = {
    'Français': 'Français',
    'Math': 'Maths',
    'SVT': 'SVT',
    'Anglais': 'Anglais',
    'Histoire Géo': 'Histoire Géo',
    'Physique': 'Physique',
    'Chimie': 'Chimie',
    'Philosophie': 'Philosophie',
    'Informatique': 'Informatique',
    'Italien': 'Italien',
    'Espagnol': 'Espagnol',
    'Allemand': 'Allemand',
    'Japonais': 'Japonais',
    'SES': 'SES',
    'Ecodroit Et Management': 'Ecodroit et Management',
    'Français Littéraire': 'Français Littéraire',
  };

  ResourceViewModel({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    fetchChaptersAndFiches();
  }

  void setSelectedLevel(String level) {
    if (_selectedLevel != level) {
      _selectedLevel = level;
      developer.log('Selected level changed to: $level');
      fetchChaptersAndFiches();
      notifyListeners();
    }
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> fetchChaptersAndFiches() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final academicClass = levelToAcademicClass[_selectedLevel] ?? '';
      developer.log(
          'Fetching chapters and fiches for academicClass: $academicClass');

      final allChapters = await _apiService.getAllChapters();
      _chapters = allChapters.where((chapter) {
        final isSubjectValid =
            subjectsByLevel[_selectedLevel]?.contains(chapter.subject) ?? false;
        final isClassValid = chapter.academicClass == academicClass;
        return isSubjectValid && isClassValid;
      }).toList();
      developer
          .log('Filtered to ${_chapters.length} chapters for $academicClass');

      _fiches = await _apiService.getAllFiches();
      developer.log(
          'Fetched ${_fiches.length} fiches: ${_fiches.map((f) => f.title).toList()}');
    } catch (e) {
      _error = 'Échec du chargement des données : ${e.toString()}';
      developer.log('Error fetching data: ${e.toString()}', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Chapter>> getChaptersForSubject(String subject) async {
    try {
      _error = null;
      final academicClass = levelToAcademicClass[_selectedLevel] ?? '';
      developer.log(
          'Fetching chapters for subject: $subject, academicClass: $academicClass');
      final chapters = await _apiService.getChaptersBySubjectAndClass(
          subject, academicClass);
      developer.log('Fetched ${chapters.length} chapters for $subject');
      return chapters;
    } catch (e) {
      _error =
          'Échec du chargement des chapitres pour $subject : ${e.toString()}';
      developer.log('Error fetching chapters for $subject: ${e.toString()}',
          error: e);
      notifyListeners();
      return [];
    }
  }

  List<String> getSubjectsForCurrentLevel() {
    return subjectsByLevel[_selectedLevel] ?? [];
  }

  String getSubjectDisplayName(String subject) {
    return subjectDisplayNames[subject] ?? subject;
  }

  Future<void> refresh() => fetchChaptersAndFiches();

  Fiche? getFicheForCourseAndChapter(String courseTitle, String chapterTitle) {
    try {
      final fiche = _fiches.firstWhere(
        (f) => f.title == courseTitle && f.chapter?['title'] == chapterTitle,
        orElse: () => Fiche(
          id: '',
          title: '',
          attachment: '',
          createdAt: '',
          updatedAt: '',
          deletedAt: null,
          chapter: null,
        ),
      );
      developer.log(
          'Fiche trouvée pour $courseTitle - $chapterTitle : ${fiche.id.isEmpty ? "Aucune" : fiche.title}');
      return fiche.id.isEmpty ? null : fiche;
    } catch (e) {
      developer.log('Erreur lors de la recherche de fiche : $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getExerciseById(String exerciseId) async {
    try {
      return await _apiService.getExerciseById(exerciseId);
    } catch (e) {
      developer.log('Error fetching exercise $exerciseId: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExercisesByChapterId(
      String chapterId) async {
    try {
      return await _apiService.getExercisesByChapterId(chapterId);
    } catch (e) {
      developer.log('Error fetching exercises for chapter $chapterId: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getQuizzesByChapterId(
      String chapterId) async {
    try {
      return await _apiService.getQuizzesByChapterId(chapterId);
    } catch (e) {
      developer.log('Error fetching quizzes for chapter $chapterId: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFlashcardsByChapterId(
      String chapterId) async {
    try {
      return await _apiService.getFlashcardsByChapterId(chapterId);
    } catch (e) {
      developer.log('Error fetching flashcards for chapter $chapterId: $e');
      rethrow;
    }
  }
}
