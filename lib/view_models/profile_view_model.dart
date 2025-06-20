import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import '../models/user.dart';

class FaqReport {
  final int id;
  final String title;
  final String description;
  final DateTime createdAt;

  FaqReport({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory FaqReport.fromJson(Map<String, dynamic> json) {
    return FaqReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ProfileViewModel extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.system;
  List<FaqReport> _faqReports = [];
  String? _faqErrorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  List<FaqReport> get faqReports => _faqReports;
  String? get faqErrorMessage => _faqErrorMessage;

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<User?> getUserDetails() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _isLoading = false;
      notifyListeners();
      return null;
    }

    if (_user != null) {
      _isLoading = false;
      notifyListeners();
      return _user;
    }

    try {
      final response = await http.get(
        Uri.parse(AppConfig.userProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _user = User.fromJson(responseData);
        await prefs.setString('user_data', jsonEncode(responseData));
        _isLoading = false;
        notifyListeners();
        return _user;
      } else if (response.statusCode == 401) {
        debugPrint("⚠️ Token expired or invalid. Please log in again.");
      } else {
        debugPrint("❌ Failed to fetch profile: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return null;
  }

  Future<User?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(userData);
      _user = User.fromJson(jsonMap);
      return _user;
    }
    return null;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('accessToken');
    _user = null;
    _faqReports = [];
    notifyListeners();
  }

  Future<bool> submitFaqReport(String title, String description) async {
    _isLoading = true;
    _faqErrorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _faqErrorMessage = "Session expirée. Veuillez vous reconnecter.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.faqReportUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _faqErrorMessage = jsonDecode(response.body)['message'] ??
            'Erreur lors de l\'envoi du rapport';
        debugPrint("❌ Failed to submit FAQ report: ${response.statusCode}");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _faqErrorMessage = 'Erreur réseau: $e';
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchFaqReports() async {
    _isLoading = true;
    _faqErrorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _faqErrorMessage = "Session expirée. Veuillez vous reconnecter.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse(AppConfig.faqReportsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _faqReports = data.map((json) => FaqReport.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _faqErrorMessage = jsonDecode(response.body)['message'] ??
            'Erreur lors de la récupération des rapports';
        debugPrint("❌ Failed to fetch FAQ reports: ${response.statusCode}");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _faqErrorMessage = 'Erreur réseau: $e';
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
