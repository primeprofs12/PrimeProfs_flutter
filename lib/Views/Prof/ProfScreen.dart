import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:primeprof/Views/Prof/messages_list.dart';
import 'package:primeprof/Views/UserManagement/login_screen.dart';
import 'package:primeprof/Views/Prof/emploi_du_temps_screen.dart';
import 'package:primeprof/view_models/course_view_model.dart';
import 'package:provider/provider.dart';
import '../UserManagement/ProfileScreen.dart';
import '../../../services/chat_service.dart';
import '../UserManagement/reservation_screen.dart';
import 'message_screen.dart';
import 'professor_drawer.dart.dart'; 

class ProfScreen extends StatefulWidget {
  const ProfScreen({super.key});

  @override
  _ProfScreenState createState() => _ProfScreenState();
}

class _ProfScreenState extends State<ProfScreen> {
  int _selectedIndex = 0;
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _recentMessages = [];

  @override
  void initState() {
    super.initState();
    _loadRecentMessages();
  }

  Future<void> _loadRecentMessages() async {
    try {
      final conversations = await _chatService.getConversations();
      setState(() {
        final allMessages = conversations
            .where((convo) => convo['lastMessage'] != null)
            .map((convo) => Map<String, dynamic>.from(convo['lastMessage'])
              ..['fullName'] = convo['fullName'] ?? 'Unknown'
              ..['userId'] = convo['userId'])
            .toList()
          ..sort((a, b) => DateTime.parse(b['timestamp'].toString())
              .compareTo(DateTime.parse(a['timestamp'].toString())));
        
        _recentMessages = allMessages.take(2).toList();
      });
    } catch (e) {
      print('Error loading recent messages: $e');
      setState(() {
        _recentMessages = [
          {
            'fullName': 'Error',
            'text': 'Failed to load messages',
            'timestamp': DateTime.now().toIso8601String(),
            'userId': '0'
          },
        ];
      });
    }
  }

  void _navigateToMessagesList(BuildContext context, Map<String, dynamic> convo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreen(
          profId: int.parse(convo['userId']?.toString() ?? '0'),
          profName: convo['fullName'] ?? 'Unknown User',
          profAvatarUrl: convo['avatarUrl'] ?? '',
        ),
      ),
    ).then((_) => _loadRecentMessages()); // Refresh messages after returning
  }

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
        break;
      case 2:
        Navigator.push(
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
  }

  Widget _buildMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          ),
          child: const Text(
            "Voir tous mes messages",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        ..._recentMessages.map((msg) => _buildMessageCard(
              msg['fullName'] ?? 'Unknown',
              msg['text'] ?? 'No message',
              _formatDate(DateTime.parse(msg['timestamp'])),
              msg['userId'].toString(),
            )),
        if (_recentMessages.isEmpty)
          const Center(child: Text("Aucun message récent")),
        TextButton(
          onPressed: () => _onItemTapped(1, context),
          child: const Center(
            child: Text(
              "Voir tous mes messages",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
        return Consumer<CourseViewModel>(
      builder: (context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: Color(0xFF748FFF)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen(role: 'teacher')),
              );
            },
          ),
        ],
      ),
      drawer: ProfessorDrawer(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => _onItemTapped(index, context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildMessagesSection(),
            const SizedBox(height: 20),
            _buildRequestSection(),
            const SizedBox(height: 20),
            _buildCoursesSection(viewModel),
            const SizedBox(height: 20),
            _buildContactButton(),
          ],
        ),
      ),
    );
          },
    );
  }

  Widget _buildMessageCard(String name, String message, String date, String userId) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundImage: AssetImage("assets/img.png"), // Fixed asset path
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(date, style: const TextStyle(color: Colors.grey)),
        onTap: () => _navigateToMessagesList(context, {
          'userId': userId,
          'fullName': name,
        }),
      ),
    );
  }

  Widget _buildRequestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mes nouvelles demandes :",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _requestCard("Khaled", "6ème année", "Accepté", Colors.green),
        _requestCard("Khaled", "3ème année", "En attente", Colors.red),
        TextButton(
          onPressed: () {},
          child: const Center(
            child: Text(
              "Voir tous mes demandes",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _requestCard(String name, String level, String status, Color statusColor) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundImage: AssetImage("assets/img.png"), // Fixed asset path
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(level),
        trailing: Text(status, style: TextStyle(color: statusColor)),
      ),
    );
  }

  Widget _buildCoursesSection(CourseViewModel viewModel) {
final now = DateTime.now();
    final upcomingCourses = viewModel.reservations
        .where((course) {
          final courseDateTime = DateTime.parse(course.date)
              .add(Duration(hours: int.parse(course.startTime.split(':')[0])));
          return courseDateTime.isAfter(now) && 
                 (course.status?.toLowerCase() != 'cancelled');
        })
        .toList()
      ..sort((a, b) {
        final aDateTime = DateTime.parse(a.date)
            .add(Duration(hours: int.parse(a.startTime.split(':')[0])));
        final bDateTime = DateTime.parse(b.date)
            .add(Duration(hours: int.parse(b.startTime.split(':')[0])));
        return aDateTime.compareTo(bDateTime);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mes prochains cours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (upcomingCourses.isEmpty)
          const Center(child: Text("Aucun cours à venir"))
        else
          ...upcomingCourses.take(2).map((course) => _buildCourseCard(
                _formatCourseDate(course.date),
                _getDayFromDate(course.date),
                "${course.startTime} - ${_getEndTime(course.startTime, course.duration)}",
                course.teacherId, // Pass teacherId to the card
              )),
      ],
    );
  }

  Widget _buildCourseCard(String date, String day, String time, int studentId) {
    return Card(
      child: ListTile(
        title: Text("$date - $day", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF748FFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text("À venir", style: TextStyle(color: Colors.white)),
        ),
        onTap: () => _navigateToReservation(context, studentId), // Navigate on tap
      ),
    );
  }
  Future<void> _navigateToReservation(BuildContext context, int profId) async {
    final viewModel = Provider.of<CourseViewModel>(context, listen: false);
    final userData = await viewModel.fetchUserById(profId);
    String profName = userData?['fullName'] ?? 'Professeur';
    String profAvatarUrl = userData?['avatar'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseBookingScreen(
          profName: profName,
          profAvatarUrl: profAvatarUrl,
          profId: profId,
          isTeacher: false, // Added the required argument
        ),
      ),
    );
  }


  Widget _buildContactButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF748FFF),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(
          "Nous contacter",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthAbbr(date.month)}';
  }

  String _getMonthAbbr(int month) {
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    return months[month - 1];
  }




  String _formatCourseDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day} ${_getMonthAbbr(date.month)}';
  }

  String _getDayFromDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[date.weekday - 1];
  }



  String _getEndTime(String startTime, int duration) {
    try {
      final format = DateFormat('HH:mm'); // Adjusted to 24-hour format
      final start = format.parse(startTime);
      final end = start.add(Duration(hours: duration)); // Duration in hours
      return DateFormat('HH:mm').format(end);
    } catch (e) {
      print('Error parsing startTime: $e');
      return startTime; // Fallback to original if parsing fails
    }
  }

}