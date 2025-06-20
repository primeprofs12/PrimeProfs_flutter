import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chapter.dart';
import '../models/fiche.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000';
  static const Duration timeoutDuration = Duration(seconds: 30);

  Future<List<Chapter>> _handleRequest(Uri uri) async {
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      developer.log('API Request: $uri');
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body (raw): ${response.body}');

      switch (response.statusCode) {
        case 200:
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data is! List) {
            developer
                .log('Réponse inattendue : la réponse n\'est pas une liste');
            throw Exception(
                'Réponse inattendue : la réponse n\'est pas une liste');
          }
          if (data.isEmpty) {
            developer.log('Aucun chapitre trouvé dans la réponse');
            return [];
          }
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => Chapter.fromJson(json))
              .toList();
        case 404:
          throw Exception('Aucun chapitre trouvé');
        case 500:
          throw Exception('Erreur serveur');
        default:
          throw Exception('Échec avec statut : ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau : $e');
    } on TimeoutException {
      throw Exception('Délai de requête dépassé');
    } on FormatException {
      throw Exception('Format de réponse invalide');
    }
  }

  Future<List<Chapter>> getChaptersBySubjectAndClass(
      String subject, String academicClass) async {
    final uri = Uri.parse('$baseUrl/chapters').replace(
      queryParameters: {
        'subject': subject,
        'academicClass': academicClass,
      },
    );
    return await _handleRequest(uri);
  }

  Future<List<Chapter>> getAllChapters() async {
    final uri = Uri.parse('$baseUrl/chapters');
    return await _handleRequest(uri);
  }

  Future<List<Fiche>> getAllFiches() async {
    final uri = Uri.parse('$baseUrl/fiches');
    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      developer.log('API Request: $uri');
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is! List) {
          developer.log('Réponse inattendue : la réponse n\'est pas une liste');
          return [];
        }
        return data
            .whereType<Map<String, dynamic>>()
            .map((json) => Fiche.fromJson(json))
            .toList();
      } else {
        throw Exception('Échec avec statut : ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau : $e');
    } on TimeoutException {
      throw Exception('Délai de requête dépassé');
    } on FormatException catch (e) {
      developer.log(
          'Erreur de formatage JSON : $e, réponse brute : ${response.body}');
      throw Exception('Format de réponse invalide');
    }
  }

  Future<Fiche> getFicheById(String id) async {
    final uri = Uri.parse('$baseUrl/fiches/$id');
    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      developer.log('API Request: $uri');
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return Fiche.fromJson(data);
        } else {
          throw Exception(
              'Réponse inattendue : la réponse n\'est pas un objet');
        }
      } else {
        throw Exception('Échec avec statut : ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau : $e');
    } on TimeoutException {
      throw Exception('Délai de requête dépassé');
    } on FormatException catch (e) {
      developer.log(
          'Erreur de formatage JSON : $e, réponse brute : ${response.body}');
      throw Exception('Format de réponse invalide');
    }
  }

  Future<Map<String, dynamic>> getExerciseById(String exerciseId) async {
    final uri = Uri.parse('$baseUrl/exercises/$exerciseId');
    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      developer.log('API Request: $uri');
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          developer.log('Réponse vide reçue pour l’exercice $exerciseId');
          return {};
        }
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          throw Exception(
              'Réponse inattendue : la réponse n\'est pas un objet JSON');
        }
      } else if (response.statusCode == 404) {
        developer.log('Exercice $exerciseId non trouvé');
        return {};
      } else {
        throw Exception(
            'Échec avec statut : ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau : $e');
    } on TimeoutException {
      throw Exception('Délai de requête dépassé');
    } on FormatException catch (e) {
      developer.log(
          'Erreur de formatage JSON : $e, réponse brute : ${response.body}');
      throw Exception('Format de réponse invalide');
    }
  }

  Future<List<Map<String, dynamic>>> getExercisesByChapterId(
      String chapterId) async {
    final uri = Uri.parse('$baseUrl/exercises').replace(
      queryParameters: {'chapterId': chapterId},
    );
    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      developer.log('API Request: $uri');
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception(
              'Réponse inattendue : la réponse n\'est pas une liste');
        }
      } else {
        throw Exception(
            'Échec avec statut : ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau : $e');
    } on TimeoutException {
      throw Exception('Délai de requête dépassé');
    } on FormatException catch (e) {
      developer.log(
          'Erreur de formatage JSON : $e, réponse brute : ${response.body}');
      throw Exception('Format de réponse invalide');
    }
  }

  Future<List<Map<String, dynamic>>> getQuizzesByChapterId(
      String chapterId) async {
    final uri = Uri.parse('$baseUrl/quizzes').replace(
      queryParameters: {'chapterId': chapterId},
    );
    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      developer.log('API Request: $uri');
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception(
              'Réponse inattendue : la réponse n\'est pas une liste');
        }
      } else {
        throw Exception(
            'Échec avec statut : ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau : $e');
    } on TimeoutException {
      throw Exception('Délai de requête dépassé');
    } on FormatException catch (e) {
      developer.log(
          'Erreur de formatage JSON : $e, réponse brute : ${response.body}');
      throw Exception('Format de réponse invalide');
    }
  }

  Future<List<Map<String, dynamic>>> getFlashcardsByChapterId(
      String chapterId) async {
    final uri = Uri.parse('$baseUrl/flashcards/chapter/$chapterId');
    late http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      developer.log('API Request: $uri');
      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body (raw): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception(
              'Réponse inattendue : la réponse n\'est pas une liste');
        }
      } else {
        throw Exception(
            'Échec avec statut : ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur réseau : $e');
    } on TimeoutException {
      throw Exception('Délai de requête dépassé');
    } on FormatException catch (e) {
      developer.log(
          'Erreur de formatage JSON : $e, réponse brute : ${response.body}');
      throw Exception('Format de réponse invalide');
    }
  }
}