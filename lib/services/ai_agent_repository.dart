import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/ai_agent_message.dart';
import 'package:intl/intl.dart';

class AiAgentRepository {
  static const String baseUrl = 'http://localhost:8002';

  Future<Map<String, dynamic>> startConversation() async {
    debugPrint('AiAgentRepository: Starting conversation');
    final response = await http.post(
      Uri.parse('$baseUrl/api/start'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );

    debugPrint('AiAgentRepository: Start response status: ${response.statusCode}, raw body: ${response.body}');
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // Explicit UTF-8 decoding
      debugPrint('AiAgentRepository: Decoded body: $decodedBody');
      return jsonDecode(decodedBody);
    } else {
      throw Exception('Failed to start conversation: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String sessionId, String message) async {
    debugPrint('AiAgentRepository: Sending message with sessionId: $sessionId, message: $message');
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'message': message, 'session_id': sessionId}),
    );

    debugPrint('AiAgentRepository: Chat response status: ${response.statusCode}, raw body: ${response.body}');
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // Explicit UTF-8 decoding
      debugPrint('AiAgentRepository: Decoded body: $decodedBody');
      return jsonDecode(decodedBody);
    } else {
      throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<AiAgentMessage>> getMessages(String sessionId) async {
    debugPrint('AiAgentRepository: Fetching state with sessionId: $sessionId');
    final response = await http.get(
      Uri.parse('$baseUrl/api/state?session_id=$sessionId'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );

    debugPrint('AiAgentRepository: State response status: ${response.statusCode}, raw body: ${response.body}');
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // Explicit UTF-8 decoding
      debugPrint('AiAgentRepository: Decoded body: $decodedBody');
      final state = jsonDecode(decodedBody);
      final message = state['message'] as String? ?? 'No message available';
      return [AiAgentMessage(
        sender: 'Agent AI',
        message: message,
        time: DateFormat('HH:mm').format(DateTime.now()),
      )];
    } else {
      throw Exception('Failed to get state: ${response.statusCode} - ${response.body}');
    }
  }
}