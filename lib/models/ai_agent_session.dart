import 'package:primeprof/models/ai_agent_message.dart';

class AiAgentSession {
  final String sessionId;
  final List<AiAgentMessage> messages;

  AiAgentSession({
    required this.sessionId,
    required this.messages,
  });

  factory AiAgentSession.fromJson(Map<String, dynamic> json) {
    return AiAgentSession(
      sessionId: json['sessionId'],
      messages: (json['messages'] as List<dynamic>)
          .map((msg) => AiAgentMessage.fromJson(msg))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }
}