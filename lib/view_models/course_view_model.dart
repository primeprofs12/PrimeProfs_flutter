import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:primeprof/config/config.dart';
import 'package:primeprof/models/user.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';

class CourseViewModel extends ChangeNotifier {
  List<CourseModel> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;

  List<CourseModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get remainingCredits => _user?.packHours;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint("Profile fetch status: ${response.statusCode}");
      debugPrint("Profile fetch response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _user = User.fromJson(responseData);
        debugPrint("Parsed packHour: ${_user?.packHours}");
      } else if (response.statusCode == 401) {
        debugPrint("⚠️ Token expired or invalid. Please log in again.");
        _errorMessage = "Token expired or invalid. Please log in again.";
      } else {
        debugPrint("❌ Failed to fetch profile: ${response.statusCode}");
        _errorMessage = "Failed to fetch profile: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _errorMessage = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reserve a course
  Future<void> reserveCourse(CourseModel course) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/reservation/reserve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'studentId': course.studentId,
          'teacherId': course.teacherId,
          'date': course.date,
          'startTime': course.startTime,
          'duration': course.duration,
        }), // Removed id and status
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newCourse = CourseModel.fromJson(jsonDecode(response.body));
        _reservations.add(newCourse);
      } else if (response.statusCode == 401) {
        debugPrint("⚠️ Token expired or invalid. Please log in again.");
        _errorMessage = "Token expired or invalid. Please log in again.";
      } else {
        debugPrint("❌ Failed to reserve course: ${response.statusCode}");
        _errorMessage = "Failed to reserve course: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _errorMessage = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel a course
  Future<void> cancelCourse(int courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _isLoading = false;
      _errorMessage = "You need to log in first.";
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/reservation/cancel/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 201) {
        _reservations.removeWhere((course) => course.id == courseId);
      } else if (response.statusCode == 401) {
        debugPrint("⚠️ Token expired or invalid. Please log in again.");
        _errorMessage = "Token expired or invalid. Please log in again.";
      } else {
        debugPrint("❌ Failed to cancel course: ${response.statusCode}");
        _errorMessage = "Failed to cancel course: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _errorMessage = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user reservations
  Future<void> fetchUserReservations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        _reservations = responseData.map((json) => CourseModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint("⚠️ Token expired or invalid. Please log in again.");
        _errorMessage = "Token expired or invalid. Please log in again.";
      } else {
        debugPrint("❌ Failed to fetch reservations: ${response.statusCode}");
        _errorMessage = "Failed to fetch reservations: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _errorMessage = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch courses by date
  Future<void> fetchCoursesByDate(String date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reservation/courses-by-date/$date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        _reservations = responseData.map((json) => CourseModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint("⚠️ Token expired or invalid. Please log in again.");
        _errorMessage = "Token expired or invalid. Please log in again.";
      } else {
        debugPrint("❌ Failed to fetch courses by date: ${response.statusCode}");
        _errorMessage = "Failed to fetch courses by date: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _errorMessage = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch reserved courses between users
  Future<void> fetchReservedCourses(int otherUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reservation/reserved-courses?otherUserId=$otherUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        _reservations = responseData.map((json) => CourseModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint("⚠️ Token expired or invalid. Please log in again.");
        _errorMessage = "Token expired or invalid. Please log in again.";
      } else {
        debugPrint("❌ Failed to fetch reserved courses: ${response.statusCode}");
        _errorMessage = "Failed to fetch reserved courses: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _errorMessage = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<Map<String, dynamic>?> fetchUserById(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('accessToken');

  if (accessToken == null) {
    debugPrint("No access token found.");
    return null;
  }

  try {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/auth/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("❌ Failed to fetch user $userId: ${response.statusCode}");
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
    return null;
  }
}
}