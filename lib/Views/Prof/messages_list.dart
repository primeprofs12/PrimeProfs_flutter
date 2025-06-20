import 'package:flutter/material.dart';
import 'package:primeprof/Views/UserManagement/login_screen.dart';
import '../../../services/chat_service.dart';
import 'package:primeprof/Views/Prof/ProfScreen.dart';
import 'package:primeprof/Views/Prof/emploi_du_temps_screen.dart';
import 'package:primeprof/Views/Prof/professor_drawer.dart.dart';
import 'message_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<dynamic>> _conversationsFuture;
  String _searchQuery = '';
  bool showArchived = false; 
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadConversations() {
    setState(() {
      _conversationsFuture = _chatService.getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Rechercher des conversations...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                showArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: const Color(0xFF748FFF),
              ),
              onPressed: () {
                setState(() {
                  showArchived = !showArchived; // Toggle the state
                });
              },
              tooltip: showArchived
                  ? 'Voir les messages non archivés'
                  : 'Voir les messages archivés',
            ),
          ),
        ],
      ),
      drawer: ProfessorDrawer(
        selectedIndex: 1,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const EmploiDuTempsScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              break;
          }
        },
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final conversations = _filterConversations(snapshot.data!);

          if (conversations.isEmpty) {
            return const Center(
              child: Text('Aucune conversation trouvée'),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final convo = conversations[index];
              final originalIndex = snapshot.data!.indexOf(convo);
              return Dismissible(
                key: Key(convo['userId'].toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _archiveMessage(originalIndex),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.archive, color: Colors.white),
                ),
                child: _buildConversationTile(convo),
              );
            },
          );
        },
      ),
    );
  }

  List<dynamic> _filterConversations(List<dynamic> conversations) {
    var filtered = conversations.where((convo) {
      final userName = (convo['fullName'] ?? 'Utilisateur ${convo['userId']}').toLowerCase();
      final lastMessage = convo['lastMessage']?['text']?.toLowerCase() ?? '';
      final isArchived = convo['isArchived'] == true || convo['isArchived'] == 'true';

      if (showArchived && !isArchived) return false;
      if (!showArchived && isArchived) return false;

      return userName.contains(_searchQuery.toLowerCase()) ||
          lastMessage.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort by last message timestamp (newest first)
    filtered.sort((a, b) {
      final aTimestamp = a['lastMessage']?['timestamp'] ?? '';
      final bTimestamp = b['lastMessage']?['timestamp'] ?? '';
      if (aTimestamp.isEmpty) return 1;
      if (bTimestamp.isEmpty) return -1;
      return DateTime.parse(bTimestamp).compareTo(DateTime.parse(aTimestamp));
    });

    return filtered;
  }

  Widget _buildConversationTile(Map<String, dynamic> convo) {
    final userName = convo['fullName'] ?? 'Utilisateur ${convo['userId']}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(
          userName[0].toUpperCase(),
          style: TextStyle(color: Colors.blue[900]),
        ),
      ),
      title: Text(userName),
      subtitle: Text(
        convo['lastMessage']?['text'] ?? 'Aucun message récent',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: convo['unreadCount'] != null && convo['unreadCount'] > 0
              ? Colors.black87
              : Colors.grey[600],
          fontWeight: convo['unreadCount'] != null && convo['unreadCount'] > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      trailing: _buildUnreadBadge(convo),
      onTap: () => _navigateToChat(convo),
    );
  }

  Widget _buildUnreadBadge(Map<String, dynamic> convo) {
    final unreadCount = convo['unreadCount'] ?? 0;
    if (unreadCount == 0) return const SizedBox.shrink();

    return CircleAvatar(
      backgroundColor: Colors.red,
      radius: 12,
      child: Text(
        unreadCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> convo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreen(
          profId: convo['userId'],
          profName: convo['fullName'] ?? 'Utilisateur ${convo['userId']}',
          profAvatarUrl: '',
        ),
      ),
    ).then((_) => _loadConversations());
  }

  void _archiveMessage(int index) {
    setState(() {
      _conversationsFuture.then((conversations) {
        conversations[index]['isArchived'] = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message archivé')),
        );
      });
    });
  }
}