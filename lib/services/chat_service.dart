import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class ChatService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getChatHistory(int otherUserId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.chatHistoryUrl}?otherUserId=$otherUserId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw _handleError(response);
  }

  Future<List<dynamic>> getConversations() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(AppConfig.conversationsUrl),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw _handleError(response);
  }

  Future<void> deleteMessage(int messageId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/chat/$messageId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  Future<void> markMessageAsRead(int messageId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${AppConfig.markReadUrl}/$messageId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw _handleError(response);
    }
  }

  dynamic _handleError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        throw Exception('Session expirée - Veuillez vous reconnecter');
      case 404:
        throw Exception('Ressource non trouvée');
      case 500:
        throw Exception('Erreur serveur');
      default:
        throw Exception('Échec de la requête: ${response.reasonPhrase}');
    }
  }
}