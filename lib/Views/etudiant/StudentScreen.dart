import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:primeprof/Views/Prof/ProfScreen.dart';
import 'package:primeprof/Views/etudiant/PaymentScreen.dart';
import 'package:primeprof/Views/etudiant/agent_ai_screen.dart';
import 'package:primeprof/view_models/ai_agent_view_model.dart';
import 'package:primeprof/view_models/course_view_model.dart';
import 'package:primeprof/view_models/login_view_model.dart';
import 'package:provider/provider.dart';
import '../Prof/message_screen.dart';
import '../UserManagement/ProfileScreen.dart';
import '../UserManagement/login_screen.dart';
import '../UserManagement/reservation_screen.dart';
import 'ResourceScreen.dart';
import 'TutorAIScreen.dart';
import 'List_chat.dart';
import '../../../services/chat_service.dart';
import 'ChatDetailsScreen.dart';
import 'student_drawer.dart';

class EtudiantScreen extends StatefulWidget {
  final String? email;  // Add email parameter
  final String? password;  // Add password parameter

  const EtudiantScreen({super.key, this.email, this.password});

  @override
  _EtudiantScreenState createState() => _EtudiantScreenState();
}

class _EtudiantScreenState extends State<EtudiantScreen> {
  int _selectedIndex = 0;
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _recentMessages = [];
  final List<String> recentResources = [
    "Resource 1",
    "Resource 2",
    "Resource 3"
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadRecentMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewCredits();
      Provider.of<CourseViewModel>(context, listen: false).fetchUserProfile();
      Provider.of<CourseViewModel>(context, listen: false)
          .fetchUserReservations();
    });
  }

  Future<void> _loadRecentMessages() async {
    try {
      final conversations = await _chatService.getConversations();
      setState(() {
        final allMessages = conversations
            .where((convo) => convo['lastMessage'] != null)
            .map((convo) => Map<String, dynamic>.from(convo['lastMessage'])
              ..['fullName'] = convo['fullName']
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
            'userId': 0
          },
        ];
      });
    }
  }

  void _checkForNewCredits() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('hoursAdded')) {
      setState(() {
        Provider.of<CourseViewModel>(context, listen: false).fetchUserProfile();
      });
    }
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
        _navigateToMessagesList(context);
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResourceScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const TutorAIScreen(cameras: [])),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentScreen()),
        );
        break;
      case 5:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        break;
    }
  }

  void _navigateToMessagesList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreenE(
          name: 'Messages',
        ),
      ),
    );
  }

  void _navigateToConversation(
      BuildContext context, String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailsScreen(
          profId: int.parse(userId),
          profName: userName,
          profAvatarUrl: '',
        ),
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
          isTeacher: false,
        ),
      ),
    );
  }

  void _showChatBubble(BuildContext context) async {
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
    final email = widget.email ?? await loginViewModel.getEmail();
    final password = widget.password ?? await loginViewModel.getPassword();

    if (email == null || password == null) {
      // If email or password is not available, redirect to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider(
        create: (context) => AiAgentViewModel(email: email, password: password),
        child: AgentAIScreen(
          email: email,
          password: password,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Tableau de bord',
                style: TextStyle(color: Color(0xFF748FFF))),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ProfileScreen(role: 'student')),
                ),
              ),
            ],
          ),
          drawer: StudentDrawer(
            selectedIndex: _selectedIndex,
            onItemTapped: (index) => _onItemTapped(index, context),
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.errorMessage != null
                  ? Center(child: Text(viewModel.errorMessage!))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          _buildCreditsSection(viewModel.remainingCredits ?? 0),
                          const SizedBox(height: 20),
                          _buildMessagesSection(),
                          const SizedBox(height: 20),
                          _buildCoursesSection(viewModel),
                          const SizedBox(height: 20),
                          _buildRecentResourcesSection(),
                          const SizedBox(height: 20),
                          _buildContactButton(),
                        ],
                      ),
                    ),
          floatingActionButton: Container(
            child: FloatingActionButton(
              onPressed: () => _showChatBubble(context),
              backgroundColor: Colors.white,
              shape: CircleBorder(
                side: BorderSide(color: Color(0xFF748FFF), width: 5),
              ),
              child: Image.asset(
                'assets/logooo.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditsSection(int remainingCredits) {
    return Card(
      child: ListTile(
        title: const Text("Crédits restants",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Nombre d'heures disponibles dans votre pack"),
        trailing: SizedBox(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                "$remainingCredits heures",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () => _navigateToMessagesList(context),
          child: const Text(
            "Voir tous mes messages",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
              child: Text("Voir tous mes messages",
                  style: TextStyle(color: Colors.redAccent))),
        ),
      ],
    );
  }

  Widget _buildMessageCard(
      String name, String message, String date, String userId) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundImage: AssetImage("img.png"),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(date, style: const TextStyle(color: Colors.grey)),
        onTap: () => _navigateToConversation(context, userId, name),
      ),
    );
  }

  Widget _buildCoursesSection(CourseViewModel viewModel) {
    final now = DateTime.now();
    final upcomingCourses = viewModel.reservations.where((course) {
      final courseDateTime = DateTime.parse(course.date)
          .add(Duration(hours: int.parse(course.startTime.split(':')[0])));
      return courseDateTime.isAfter(now) &&
          (course.status?.toLowerCase() != 'cancelled');
    }).toList()
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
        const Text("Mes prochains cours",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (upcomingCourses.isEmpty)
          const Center(child: Text("Aucun cours à venir"))
        else
          ...upcomingCourses.take(2).map((course) => _buildCourseCard(
                _formatCourseDate(course.date),
                _getDayFromDate(course.date),
                "${course.startTime} - ${_getEndTime(course.startTime, course.duration)}",
                course.teacherId,
              )),
      ],
    );
  }

  Widget _buildCourseCard(String date, String day, String time, int teacherId) {
    return Card(
      child: ListTile(
        title: Text("$date - $day",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF748FFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text("À venir", style: TextStyle(color: Colors.white)),
        ),
        onTap: () => _navigateToReservation(context, teacherId),
      ),
    );
  }

  Widget _buildRecentResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mes dernières Ressources consultées",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...recentResources.map((resource) => _buildResourceCard(resource)),
        TextButton(
          onPressed: () {},
          child: const Center(
              child: Text("Voir tous les ressources",
                  style: TextStyle(color: Colors.redAccent))),
        ),
      ],
    );
  }

  Widget _buildResourceCard(String resource) {
    return Card(
      child: ListTile(
        title:
            Text(resource, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text("Nous contacter",
            style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthAbbr(date.month)}';
  }

  String _formatCourseDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day} ${_getMonthAbbr(date.month)}';
  }

  String _getDayFromDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return days[date.weekday - 1];
  }

  String _getMonthAbbr(int month) {
    const months = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'jun',
      'jul',
      'aoû',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return months[month - 1];
  }

  String _getEndTime(String startTime, int duration) {
    try {
      final format = DateFormat('HH:mm');
      final start = format.parse(startTime);
      final end = start.add(Duration(minutes: duration));
      return DateFormat('HH:mm').format(end);
    } catch (e) {
      print('Error parsing startTime: $e');
      return startTime;
    }
  }
}
