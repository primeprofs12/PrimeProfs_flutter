import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:primeprof/services/ai_agent_repository.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import '../models/user.dart';


class LoginViewModel extends ChangeNotifier {
  final AiAgentRepository _aiAgentRepository = AiAgentRepository();

  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);

        // Store session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', authResponse.accessToken);
        final expirationTime = DateTime.now().add(const Duration(days: 31)).toIso8601String();
        await prefs.setString('session_expiration', expirationTime);

        // Store email and password
        await prefs.setString('email', email);
        await prefs.setString('password', password);

        // Fetch and store user role if not in response
        String? role = authResponse.role;
        if (role == null) {
          role = await fetchUserRole(authResponse.accessToken);
        }
        if (role != null) {
          await prefs.setString('role', role);
          await prefs.setBool('isLoggedIn', true);
        } else {
          debugPrint('Error: User role not found.');
        }

        // Retrieve or initialize sessionId
        if (authResponse.sessionId != null) {
          await prefs.setString('sessionId', authResponse.sessionId!);
        } 

        notifyListeners();
        return authResponse;
      } else {
        debugPrint('Login error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e\nStack trace: $stackTrace');
      return null;
    }
  }

  Future<String?> fetchUserRole(String accessToken) async {
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
        print("Role Response: ${responseData['role']}");
        return responseData['role'] as String?;
      } else {
        debugPrint('Role fetch error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Role fetch error: $e');
      return null;
    }
  }

  Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationTime = prefs.getString('session_expiration');
    if (expirationTime != null) {
      final expirationDate = DateTime.parse(expirationTime);
      return DateTime.now().isAfter(expirationDate);
    }
    return true;
  }

  Future<String?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sessionId');
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final expirationTime = prefs.getString('session_expiration');
    if (accessToken != null && expirationTime != null) {
      final expirationDate = DateTime.parse(expirationTime);
      if (!DateTime.now().isAfter(expirationDate)) {
        final role = await getCurrentUserRole();
        final sessionId = await getSessionId();
        if (role != null && sessionId != null) {
          debugPrint('Session restored successfully.');
          return true;
        }
      }
    }
    debugPrint('Session restoration failed or expired.');
    return false;
  }

  Future<void> saveUserData(String userId, Map<String, dynamic> userData) async {
    try {
      if (kDebugMode) {
        print('User data saved successfully.');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
    }
  }
}