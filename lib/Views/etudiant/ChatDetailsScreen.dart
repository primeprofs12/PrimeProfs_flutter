import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/chat_service.dart';
import '../../../services/socket_service.dart';
import '../UserManagement/reservation_screen.dart';
import 'dart:convert';
import 'package:flutter/gestures.dart';

class ChatDetailsScreen extends StatefulWidget {
  final int profId;
  final String profName;
  final String profAvatarUrl;

  const ChatDetailsScreen({
    Key? key,
    required this.profId,
    required this.profName,
    required this.profAvatarUrl,
  }) : super(key: key);

  @override
  _ChatDetailsScreenState createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final RegExp _urlRegExp = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

  int? _currentUserId;
  bool _isLoading = true;
  bool _isSending = false;
  String? _replyingTo;
  String? _currentEditingId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    SocketService.disconnect();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      await SocketService.initialize();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        print('No access token found');
        _showErrorDialog('Please login again to continue', redirectToLogin: true);
        return;
      }

      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Invalid token format');
        }

        String normalizedPayload = base64Url.normalize(parts[1]);
        final payloadMap = json.decode(utf8.decode(base64Url.decode(normalizedPayload)));
        
        final userId = payloadMap['userId'] ?? payloadMap['sub'] ?? payloadMap['id'];
        final userFullName = payloadMap['fullName'] ?? payloadMap['name'] ?? 'You';
        
        if (userId == null) {
          throw Exception('No user ID found in token');
        }

        setState(() {
          _currentUserId = userId is String ? int.parse(userId) : userId;
          print('Retrieved userId from token: $_currentUserId');
          print('Retrieved user fullName: $userFullName');
        });
      } catch (e) {
        print('Error decoding token: $e');
        _showErrorDialog('Error getting user information. Please login again.', redirectToLogin: true);
        return;
      }

      await _loadChatHistory();
      _setupSocketListeners();
    } catch (e) {
      print('Error in _initializeChat: $e');
      _showErrorDialog('Error initializing chat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _chatService.getChatHistory(widget.profId);
      print('Chat history received: $history');
      
      setState(() {
        final sortedMessages = history.map((message) {
          var typedMessage = Map<String, dynamic>.from(message);
          
          if (typedMessage.containsKey('lastMessage')) {
            var lastMessage = Map<String, dynamic>.from(typedMessage['lastMessage']);
            lastMessage['fullName'] = typedMessage['fullName'];
            lastMessage['userId'] = typedMessage['userId'];
            typedMessage = lastMessage;
          }

          var senderId = typedMessage['senderId'];
          if (senderId is String) 
            senderId = int.parse(senderId);
          typedMessage['senderId'] = senderId;
          return typedMessage;
        }).toList()
          ..sort((a, b) => DateTime.parse(a['timestamp'].toString())
              .compareTo(DateTime.parse(b['timestamp'].toString())));

        _messages.clear();
        _messages.addAll(sortedMessages);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch(e) {
      print("Error loading chat history: $e");
      _showErrorDialog("Error loading chat history: $e");
    }
  }

  void _setupSocketListeners() {
    try {
      SocketService.onMessageReceived((data) {
        print('Socket message received: $data');
        if (data['senderId'] != null) {
          final Map<String, dynamic> typedMessage = Map<String, dynamic>.from(data);
          var senderId = typedMessage['senderId'];
          if (senderId is String) 
            senderId = int.parse(senderId);
          
          if (senderId == widget.profId || senderId == _currentUserId) {
            setState(() {
              typedMessage['senderId'] = senderId;
              _messages.add(typedMessage);
            });
            _scrollToBottom();
          }
        }
      });

      SocketService.onTypingReceived((data) {
        final sender = data["sender"] is String ? int.tryParse(data["sender"]) : data["sender"];
        if (sender == widget.profId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.profName} est en train d\'écrire...'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      print("Error setting up socket listeners: $e");
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || _isSending || _currentUserId == null) return;

    setState(() => _isSending = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userFullName = prefs.getString("fullName") ?? "You";

      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': _currentUserId,
        'fullName': userFullName,
        'recipientId': widget.profId,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      };

      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();

      SocketService.sendMessage({
        'recipientId': widget.profId,
        'message': text,
        'senderId': _currentUserId,
        'fullName': userFullName,
      });

      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
      _showErrorDialog("Error sending message: $e");
      setState(() {
        _messages.removeLast();
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showErrorDialog(String message, {bool redirectToLogin = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (redirectToLogin) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadChatHistory,
              child: _messages.isEmpty
                  ? Center(child: Text('Aucun message', style: TextStyle(color: theme.colorScheme.onSurface)))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (ctx, index) {
                        final message = _messages[_messages.length - 1 - index];
                        final isCurrentUser = message['senderId'] == _currentUserId;
                        return GestureDetector(
                          onLongPress: () => _showMessageOptions(context, message),
                          child: _buildMessageBubble(message, isCurrentUser, theme),
                        );
                      },
                    ),
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.profAvatarUrl.isNotEmpty
                ? NetworkImage(widget.profAvatarUrl)
                : null,
            child: widget.profAvatarUrl.isEmpty
                ? Text(widget.profName.isNotEmpty ? widget.profName[0].toUpperCase() : 'P',
                    style: TextStyle(color: theme.colorScheme.onSurface))
                : null,
            backgroundColor: theme.colorScheme.surface,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.profName.isNotEmpty ? widget.profName : 'Professeur',
                  style: TextStyle(color: theme.colorScheme.onPrimary)),
              Text('En ligne',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimary.withOpacity(0.7))),
            ],
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.primary,
    );
  }


  Future<void> _launchUrl(String url) async {
    if (url.startsWith("www.")) {
      url = "http://$url";
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  List<InlineSpan> _buildTextWithLinks(String text, ThemeData theme) {
    final List<InlineSpan> textSpans = [];
    final matches = _urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      textSpans.add(TextSpan(text: text));
      return textSpans;
    }

    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        textSpans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
        ));
      }
      
      final url = text.substring(match.start, match.end);
      textSpans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
      ));
      
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      textSpans.add(TextSpan(
        text: text.substring(lastMatchEnd),
      ));
    }

    return textSpans;
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isCurrentUser, ThemeData theme) {
    final senderId = message["senderId"] is String ? int.parse(message["senderId"]) : (message["senderId"] as int);
    isCurrentUser = senderId == _currentUserId;
    final senderName = isCurrentUser ? (message["fullName"] ?? "You") : (message["fullName"] ?? widget.profName);
    final messageText = message["text"] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser && widget.profAvatarUrl.isNotEmpty) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.profAvatarUrl),
              backgroundColor: theme.colorScheme.surface,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
                  child: Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : theme.colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isCurrentUser ? const Radius.circular(16) : const Radius.circular(0),
                      bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_replyingTo != null && message['id'] == _currentEditingId)
                        Text('Replying to: $_replyingTo',
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          children: _buildTextWithLinks(messageText, theme),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(DateTime.parse(message['timestamp'])),
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Icon(
                              message['isRead'] == true ? Icons.done_all : Icons.done,
                              size: 16,
                              color: message['isRead'] == true
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                filled: true,
                fillColor: theme.colorScheme.surface,
                suffixIcon: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              enabled: !_isSending,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
            onPressed: _isSending ? null : () => _sendMessage(_messageController.text.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return BottomAppBar(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseBookingScreen(
                  profId: widget.profId,
                  profName: widget.profName,
                  profAvatarUrl: widget.profAvatarUrl,
                  isTeacher: false, // Add the required argument
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: const Text('Réserver un cours', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showMessageOptions(BuildContext context, Map<String, dynamic> message) {
    final isUser = message["senderId"] == _currentUserId;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUser) ...[
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Supprimer'),
                onTap: () => _deleteMessage(message),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier'),
                onTap: () => _editMessage(message),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Répondre'),
                onTap: () => _replyToMessage(message),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _deleteMessage(Map<String, dynamic> message) {
    setState(() => _messages.remove(message));
    Navigator.pop(context);
  }

  void _editMessage(Map<String, dynamic> message) {
    _messageController.text = message["text"] ?? "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(
          controller: _messageController,
          decoration: const InputDecoration(hintText: 'Modifier votre message'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final updatedText = _messageController.text.trim();
              if (updatedText.isNotEmpty) {
                setState(() {
                  final index = _messages.indexOf(message);
                  if (index != -1) {
                    _messages[index]['text'] = updatedText;
                    _messages[index]['timestamp'] = DateTime.now().toIso8601String();
                  }
                });
              }
              _messageController.clear();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _replyToMessage(Map<String, dynamic> message) {
    setState(() {
      _replyingTo = message['text'];
      _currentEditingId = message['id'];
    });
    Navigator.pop(context);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}