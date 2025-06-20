import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:primeprof/Views/Prof/messages_list.dart';
import 'package:primeprof/Views/UserManagement/login_screen.dart';
import 'package:primeprof/Views/Prof/ProfScreen.dart';
import 'package:primeprof/models/course_model.dart';
import 'package:primeprof/view_models/course_view_model.dart';
import 'package:primeprof/view_models/login_view_model.dart';
import 'package:provider/provider.dart';
import '../UserManagement/ProfileScreen.dart';
import 'professor_drawer.dart.dart';

class EmploiDuTempsScreen extends StatefulWidget {
  const EmploiDuTempsScreen({super.key});

  @override
  _EmploiDuTempsScreenState createState() => _EmploiDuTempsScreenState();
}

class _EmploiDuTempsScreenState extends State<EmploiDuTempsScreen> {
  String selectedDate = "";

  @override
  void initState() {
    super.initState();
    selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchCoursesForDate(selectedDate);
  }

  Future<void> _fetchCoursesForDate(String date) async {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    final role = await Provider.of<LoginViewModel>(context, listen: false).getCurrentUserRole();
    if (role != null) {
      await courseViewModel.fetchCoursesByDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courseViewModel = Provider.of<CourseViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emploi du temps',
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: theme.colorScheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(role: 'teacher')),
              );
            },
          ),
        ],
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      ),
      drawer: ProfessorDrawer(
        selectedIndex: 2,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ChatScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          }
        },
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/img.png'),
                    backgroundColor: theme.colorScheme.onSurface,
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    DateTime currentDate = DateTime.now().add(Duration(days: index));
                    String day = DateFormat('yyyy-MM-dd').format(currentDate);
                    String weekDay = DateFormat('EEE').format(currentDate);
                    return _buildDateBox(day, weekDay, selectedDate == day, () {
                      setState(() {
                        selectedDate = day;
                      });
                      _fetchCoursesForDate(selectedDate);
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: courseViewModel.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : courseViewModel.reservations.isEmpty
                        ? Center(child: Text('Aucun cours disponible pour cette date.'))
                        : ListView.builder(
                            itemCount: courseViewModel.reservations.length,
                            itemBuilder: (context, index) {
                              final course = courseViewModel.reservations[index];
                              return _buildAppointmentTile(course);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox(String day, String weekDay, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('d').format(DateTime.parse(day)),
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            Text(
              weekDay,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTile(CourseModel course) {
    final theme = Theme.of(context);
    
    // Debug print to see what data we're working with
    print('Course data: studentId=${course.studentId}, teacherId=${course.teacherId}');
    
    // For a teacher's schedule, we need to display the student's name
    // The studentId field in the CourseModel should contain the ID of the student
    return _buildCourseCardWithStudentInfo(course, theme);
  }

  Widget _buildCourseCardWithStudentInfo(CourseModel course, ThemeData theme) {
    // If there's no student ID, we can't fetch the student's name
    if (course.studentId == null) {
      return _buildCourseCard("Pas d'étudiant assigné", "", course, theme);
    }
    
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    
    return FutureBuilder<Map<String, dynamic>?>(
      // Explicitly fetch the student's data using the studentId
      future: courseViewModel.fetchUserById(course.teacherId!),
      builder: (context, snapshot) {
        // Default values
        String studentName = "Étudiant non assigné";
        String avatarUrl = "";
        
        // Debug print to see what data we're getting from the API
        if (snapshot.hasData) {
          print('Student data from API: ${snapshot.data}');
        } else if (snapshot.hasError) {
          print('Error fetching student data: ${snapshot.error}');
        }
        
        // Update values if we have data
        if (snapshot.connectionState == ConnectionState.waiting) {
          studentName = "Chargement...";
        } else if (snapshot.hasData && snapshot.data != null) {
          studentName = snapshot.data!['fullName'] ?? "Étudiant #${course.studentId}";
          avatarUrl = snapshot.data!['avatar'] ?? "";
        } else if (course.studentId != null) {
          studentName = "Étudiant #${course.studentId}";
        }
        
        return _buildCourseCard(studentName, avatarUrl, course, theme);
      },
    );
  }

  Widget _buildCourseCard(String studentName, String avatarUrl, CourseModel course, ThemeData theme) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course header with time and duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      '${course.startTime}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${course.duration}h',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Student information section - This is the "studentmark" section
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: avatarUrl.isNotEmpty 
                        ? NetworkImage(avatarUrl) as ImageProvider
                        : AssetImage('assets/img.png'),
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étudiant',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          studentName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Course status
            if (course.status != null)
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(course.status!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Statut: ${course.status}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getStatusColor(course.status!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}