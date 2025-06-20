import 'package:intl/intl.dart';

class AiAgentMessage {
  final String sender;
  final String message;
  final String time;

  AiAgentMessage({
    required this.sender,
    required this.message,
    required this.time,
  });

  factory AiAgentMessage.fromJson(Map<String, dynamic> json) {
    return AiAgentMessage(
      sender: json['sender'] as String? ?? 'Agent AI',
      message: json['message'] as String? ?? 'No message',
      time: json['time'] as String? ?? DateFormat('HH:mm').format(DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'time': time,
    };
  }
}