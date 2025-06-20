import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:primeprof/view_models/course_view_model.dart';
import 'package:primeprof/models/course_model.dart';
import 'package:primeprof/Views/etudiant/PaymentScreen.dart'; 

import 'dart:developer' as developer;

class CourseBookingScreen extends StatefulWidget {
  final String profName;
  final String profAvatarUrl;
  final int profId;
  final bool isTeacher; // Flag to determine if user is teacher or student

  const CourseBookingScreen({
    super.key,
    required this.profName,
    required this.profAvatarUrl,
    required this.profId,
    required this.isTeacher,
  });

  @override
  _CourseBookingScreenState createState() => _CourseBookingScreenState();
}

class _CourseBookingScreenState extends State<CourseBookingScreen>
    with SingleTickerProviderStateMixin {
  int selectedHours = 1;
  int selectedTime = 13;
  int selectedDay = DateTime.now().day;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<int> days = List.generate(31, (index) => index + 1);
  List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  List<int> years = List.generate(10, (index) => DateTime.now().year + index);

  // Only used for student role
  int remainingPackHours = 0;
  
  Set<int> coursesInDeleteMode = {};
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  void _fetchUserData() {
    final viewModel = Provider.of<CourseViewModel>(context, listen: false);
    viewModel.fetchUserReservations();
    
    // Only fetch profile for students (to get remaining hours)
    if (!widget.isTeacher) {
      viewModel.fetchUserProfile();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sélectionnez une date',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Icon(Icons.calendar_today,
                      color: theme.colorScheme.primary, size: 24),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDatePickerWheel(
                      days, selectedDay - 1, (value) => setState(() => selectedDay = value + 1)),
                  _buildDatePickerWheel(
                      months, selectedMonth - 1, (value) => setState(() => selectedMonth = value + 1)),
                  _buildDatePickerWheel(years, years.indexOf(selectedYear),
                      (value) => setState(() => selectedYear = years[value])),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: Text(
                  'Confirmer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerWheel(
      List<dynamic> items, int initialIndex, Function(int) onChanged) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 70,
      height: 150,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: CupertinoPicker(
        backgroundColor: Colors.transparent,
        itemExtent: 32,
        onSelectedItemChanged: onChanged,
        scrollController: FixedExtentScrollController(initialItem: initialIndex),
        looping: true,
        children: List.generate(
          items.length,
          (index) => Center(
            child: Text(
              '${items[index]}',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }

  // Only for student role
  void _showPurchasePackDialog(BuildContext context) async {
    if (widget.isTeacher) return; // Safety check
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen()),
    );
    
    if (result != null && result.containsKey('hoursAdded')) {
      // Refresh user profile to get updated pack hours
      Provider.of<CourseViewModel>(context, listen: false).fetchUserProfile();
    }
  }

  CourseModel _createCourseFromSelection() {
    final formattedDate = DateTime(
      selectedYear,
      selectedMonth,
      selectedDay,
    ).toIso8601String().split('T')[0];

    return CourseModel(
      teacherId: widget.profId,
      date: formattedDate,
      startTime: "$selectedTime:00",
      duration: selectedHours,
      status: "pending",
    );
  }

  Future<void> _reserveCourse() async {
    final viewModel = Provider.of<CourseViewModel>(context, listen: false);
    final course = _createCourseFromSelection();

    try {
      await viewModel.reserveCourse(course);

      if (viewModel.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réservation ajoutée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh data
        viewModel.fetchUserReservations();
        if (!widget.isTeacher) {
          viewModel.fetchUserProfile();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('Error reserving course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réservation: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showReservationConfirmationPopup(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Réservation confirmée',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 24),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Votre réservation a été effectuée avec succès!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  Text(
                    'Professeur : ${widget.profName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Date : $selectedDay ${months[selectedMonth - 1]} $selectedYear',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Heure : $selectedTime h',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Durée : $selectedHours h',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _reserveCourse();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: Text(
                  'Confirmer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.teal,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Center(
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  void _toggleDeleteMode(int? courseId) {
    if (courseId == null) return;

    setState(() {
      if (coursesInDeleteMode.contains(courseId)) {
        coursesInDeleteMode.remove(courseId);
      } else {
        coursesInDeleteMode.clear();
        coursesInDeleteMode.add(courseId);
      }
    });
  }

  void _clearDeleteModes() {
    if (coursesInDeleteMode.isNotEmpty) {
      setState(() {
        coursesInDeleteMode.clear();
      });
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showCancelConfirmationDialog(CourseModel course, int index) {
    final theme = Theme.of(context);
    final viewModel = Provider.of<CourseViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Annuler le cours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir annuler ce cours?\n\nDate: ${_formatDate(course.date)}\nHeure: ${course.startTime.split(':')[0]}h\nDurée: ${course.duration}h',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Non',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _clearDeleteModes();
              
              if (course.id != null) {
                // Get the current list of reservations
                final reservations = viewModel.reservations
                    .where((c) => c.teacherId == widget.profId && c.status?.toLowerCase() != 'cancelled')
                    .toList();
                
                // Find the index of the course to remove
                final indexToRemove = reservations.indexWhere((c) => c.id == course.id);
                
                if (indexToRemove != -1) {
                  // Remove the item from the list with animation
                  setState(() {
                    reservations.removeAt(indexToRemove);
                  });
                  
                  // Call the API to cancel the course
                  await viewModel.cancelCourse(course.id!);
                  
                  // Refresh the list from the server
                  viewModel.fetchUserReservations();
                  if (!widget.isTeacher) {
                    viewModel.fetchUserProfile();
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Oui, annuler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservedCourseCard(CourseModel course, int index) {
    final theme = Theme.of(context);
    final courseId = course.id;
    final isInDeleteMode = courseId != null && coursesInDeleteMode.contains(courseId);

    return GestureDetector(
      onTap: () => _toggleDeleteMode(courseId),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isInDeleteMode 
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5) 
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${course.startTime.split(':')[0]}h',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDate(course.date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${course.duration}h',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Divider(height: 1, color: theme.dividerColor),
                  SizedBox(height: 10),
                  if (course.status != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          course.status!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(course.status!),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (isInDeleteMode)
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () {
                    _showCancelConfirmationDialog(course, index);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CourseViewModel>(
      builder: (context, viewModel, child) {
        // Update remaining hours for student role
        if (!widget.isTeacher && viewModel.remainingCredits != null) {
          remainingPackHours = viewModel.remainingCredits!;
        }
        
        final professorReservations = viewModel.reservations
            .where((course) => course.teacherId == widget.profId && course.status?.toLowerCase() != 'cancelled')
            .toList();

        return GestureDetector(
          onTap: _clearDeleteModes,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Réserver un cours',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: viewModel.isLoading && professorReservations.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              color: theme.scaffoldBackgroundColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      widget.profName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    
                                    // Only show remaining hours for students
                                    if (!widget.isTeacher)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        margin: EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.shadowColor.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Heures restantes: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              '$remainingPackHours h',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          'Horaire',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Date',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Durée',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Column(
                                              children: [
                                                _buildCircularButton(
                                                    Icons.add,
                                                    () => setState(
                                                        () => selectedTime < 23 ? selectedTime++ : null)),
                                                _buildCircularButton(
                                                    Icons.remove,
                                                    () => setState(
                                                        () => selectedTime > 0 ? selectedTime-- : null)),
                                              ],
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: theme.shadowColor.withOpacity(0.2),
                                                    spreadRadius: 2,
                                                    blurRadius: 10,
                                                  )
                                                ],
                                              ),
                                              child: Text(
                                                '$selectedTime h',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () => _showDatePicker(context),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: theme.shadowColor.withOpacity(0.2),
                                                  spreadRadius: 2,
                                                  blurRadius: 10,
                                                )
                                              ],
                                            ),
                                            child: Text(
                                              '$selectedDay ${months[selectedMonth - 1]} $selectedYear',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: theme.shadowColor.withOpacity(0.2),
                                                    spreadRadius: 2,
                                                    blurRadius: 10,
                                                  )
                                                ],
                                              ),
                                              child: Text(
                                                '$selectedHours h',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onPrimary,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Column(
                                              children: [
                                                _buildCircularButton(Icons.add,
                                                    () => setState(() => selectedHours++)),
                                                _buildCircularButton(
                                                    Icons.remove,
                                                    () => setState(
                                                        () => selectedHours > 1 ? selectedHours-- : null)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 30),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Mes cours reservés',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      constraints: BoxConstraints(maxHeight: 300),
                                      child: professorReservations.isEmpty
                                          ? Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: Text(
                                                  'Aucun cours réservé',
                                                  style: TextStyle(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : AnimatedSwitcher(
                                              duration: Duration(milliseconds: 300),
                                              transitionBuilder: (Widget child, Animation<double> animation) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: Offset(0.1, 0.0),
                                                      end: Offset.zero,
                                                    ).animate(animation),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: ListView.builder(
                                                key: ValueKey<int>(professorReservations.length),
                                                shrinkWrap: true,
                                                physics: AlwaysScrollableScrollPhysics(),
                                                itemCount: professorReservations.length,
                                                itemBuilder: (context, index) {
                                                  return _buildReservedCourseCard(professorReservations[index], index);
                                                },
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16.0),
                        width: double.infinity,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              _clearDeleteModes();
                              
                              // For students, check if they have enough hours
                              if (!widget.isTeacher && remainingPackHours < selectedHours) {
                                _showPurchasePackDialog(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Heures insuffisantes! Redirection vers l\'achat de pack.'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                _showReservationConfirmationPopup(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Réserver',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
          ),
        );
      },
    );
  }
}