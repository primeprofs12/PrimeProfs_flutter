import 'package:primeprof/config/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static io.Socket? _socket;

  static io.Socket get socket {
    if (_socket == null) throw Exception('Socket non initialisée');
    return _socket!;
  }

  static Future<void> initialize() async {
    if (_socket != null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    
    _socket = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setQuery({'token': token})
        .build(),
    );

    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static void onMessageReceived(Function(dynamic) handler) {
    _socket?.on('message', handler);
  }

  static void onTypingReceived(Function(dynamic) handler) {
    _socket?.on('typingNotification', handler);
  }

  static void sendMessage(Map<String, dynamic> message) {
    _socket?.emit('sendMessage', message);
  }
}