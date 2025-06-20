import 'package:flutter/material.dart';
import 'package:primeprof/services/ai_agent_repository.dart';
import '../models/ai_agent_message.dart';
import 'package:intl/intl.dart';

class AiAgentViewModel with ChangeNotifier {
  final AiAgentRepository _repository = AiAgentRepository();
  List<AiAgentMessage> _messages = [];
  bool _isLoading = false;
  String? _sessionId;
  final String? email;
  final String? password;

  List<AiAgentMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get sessionId => _sessionId;

  AiAgentViewModel({this.email, this.password});

  Future<void> startConversation(String sessionId) async {
    try {
      _isLoading = true;
      debugPrint('AiAgentViewModel: Starting conversation with email: $email, password: $password');
      notifyListeners();

      // Start a new session with the server
      final response = await _repository.startConversation();
      _sessionId = response['session_id'] as String?;
      _messages.addAll(await _repository.getMessages(_sessionId!));
      debugPrint('AiAgentViewModel: Started with sessionId: $_sessionId, messages: ${_messages.length}');
    } catch (e) {
      debugPrint('AiAgentViewModel: Error starting conversation: $e');
      _messages.add(AiAgentMessage(
        sender: 'Agent AI',
        message: 'Erreur lors du démarrage: $e',
        time: DateFormat('HH:mm').format(DateTime.now()),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty || _sessionId == null) {
      debugPrint('AiAgentViewModel: Cannot send message: sessionId is null or message is empty.');
      return;
    }

    // Add user message
    final userMessage = AiAgentMessage(
      sender: 'You',
      message: message,
      time: DateFormat('HH:mm').format(DateTime.now()),
    );
    _messages.add(userMessage);
    debugPrint('AiAgentViewModel: Added user message: ${userMessage.message}');

    try {
      _isLoading = true;
      debugPrint('AiAgentViewModel: Sending message: $message with sessionId: $_sessionId');
      notifyListeners();

      // Send message to the server and update messages
      await _repository.sendMessage(_sessionId!, message);
      _messages.addAll(await _repository.getMessages(_sessionId!));
      debugPrint('AiAgentViewModel: Updated messages, total: ${_messages.length}');
    } catch (e) {
      debugPrint('AiAgentViewModel: Error sending message: $e');
      _messages.add(AiAgentMessage(
        sender: 'Agent AI',
        message: 'Erreur: $e',
        time: DateFormat('HH:mm').format(DateTime.now()),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}