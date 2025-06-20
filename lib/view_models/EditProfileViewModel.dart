import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import '../models/user.dart';

class EditProfileViewModel extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.system;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? _editedFullName;
  String? _editedEmail;
  int? _editedAge;
  String? _editedGrade;
  String? _errorMessage;
  int? _userId;

  User? get user => _user;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  String? get fullName => _editedFullName ?? _user?.fullName;
  String? get email => _editedEmail ?? _user?.email;
  int? get age => _editedAge ?? _user?.age;
  String? get grade => _editedGrade ?? _user?.grade;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;

  EditProfileViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await getCachedUser();
      _userId = prefs.getInt('userId');
      if (_user == null || _userId == null) {
        await getUserDetails();
        _userId ??= prefs.getInt('userId');
      }
      
      // Load theme preference
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des données: $e';
      debugPrint("❌ Initialization error: $e");
    } finally {
      _setLoading(false);
    }
  }

  void setFullName(String? value) {
    _editedFullName = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setEmail(String? value) {
    _editedEmail = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setAge(int? value) {
    _editedAge = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setGrade(String? value) {
    _editedGrade = value;
    _errorMessage = null;
    notifyListeners();
  }

  Future<User?> getUserDetails() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      debugPrint("No access token found. User is not logged in.");
      _setLoading(false);
      return null;
    }

    // Return cached user if available and not forcing refresh
    if (_user != null) {
      _setLoading(false);
      return _user;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/profile'),
        headers: _authHeaders(accessToken),
      );

      if (response.statusCode == 200) {
        // Safely parse the response body
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response body');
        }
        
        final dynamic decodedResponse = jsonDecode(responseBody);
        
        // Handle different response structures
        if (decodedResponse is Map<String, dynamic>) {
          Map<String, dynamic> userData;
          
          // Check if the response has a 'user' field
          if (decodedResponse.containsKey('user')) {
            final userField = decodedResponse['user'];
            
            // Ensure the user field is a Map
            if (userField is Map<String, dynamic>) {
              userData = userField;
            } else {
              // If user field exists but isn't a Map, use the whole response
              userData = decodedResponse;
            }
          } else {
            // If no user field, use the whole response
            userData = decodedResponse;
          }
          
          // Create user from the userData
          _user = User.fromJson(userData);
          
          // Cache the user data
          await prefs.setString('user_data', jsonEncode(_user!.toJson()));
          
          _setLoading(false);
          return _user;
        } else {
          throw Exception('Invalid response format: $decodedResponse');
        }
      } else if (response.statusCode == 401) {
        // Handle expired token
        _errorMessage = "Session expirée - Veuillez vous reconnecter";
        await clearUserData();
      } else {
        debugPrint("❌ Failed to fetch profile: ${response.statusCode} - ${response.body}");
        _errorMessage = "Erreur lors du chargement du profil: ${response.statusCode}";
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Network error: $e\nStack trace: $stackTrace");
      _errorMessage = "Erreur réseau: $e";
      
      // If we have a cached user, return it as fallback
      if (_user != null) {
        _setLoading(false);
        return _user;
      }
    }
    
    _setLoading(false);
    return null;
  }

  Future<User?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null && userData.isNotEmpty) {
        final jsonMap = jsonDecode(userData) as Map<String, dynamic>;
        _user = User.fromJson(jsonMap);
        return _user;
      }
    } catch (e) {
      debugPrint("❌ Error loading cached user: $e");
    }
    return null;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('user_data'),
      prefs.remove('accessToken'),
      prefs.remove('userId'),
    ]);
    _user = null;
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      _errorMessage = "Vous devez vous connecter pour modifier votre profil.";
      debugPrint("No access token found.");
      _setLoading(false);
      return false;
    }

    if (_user == null) {
      _errorMessage = "Aucune donnée utilisateur disponible.";
      debugPrint("No user data available.");
      _setLoading(false);
      return false;
    }

    try {
      final body = <String, dynamic>{};
      if (_editedFullName != null && _editedFullName != _user!.fullName) {
        body['fullName'] = _editedFullName;
      }
      if (_editedEmail != null && _editedEmail != _user!.email) {
        body['email'] = _editedEmail;
      }
      if (_editedAge != null && _editedAge != _user!.age) {
        body['age'] = _editedAge;
      }
      if (_editedGrade != null && _editedGrade != _user!.grade) {
        body['grade'] = _editedGrade;
      }

      if (body.isEmpty) {
        debugPrint("Aucune modification détectée.");
        _setLoading(false);
        return true; // No changes, default success
      }

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/auth/update'),
        headers: _authHeaders(accessToken),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Safely parse the response
        final responseBody = response.body;
        if (responseBody.isNotEmpty) {
          try {
            final responseData = jsonDecode(responseBody);
            
            // Update the user object with the new data
            // First create a copy of the current user data
            final updatedUserData = _user!.toJson();
            
            // Update with edited fields
            if (_editedFullName != null) updatedUserData['fullName'] = _editedFullName;
            if (_editedEmail != null) updatedUserData['email'] = _editedEmail;
            if (_editedAge != null) updatedUserData['age'] = _editedAge;
            if (_editedGrade != null) updatedUserData['grade'] = _editedGrade;
            
            // Create a new user object with the updated data
            _user = User.fromJson(updatedUserData);
            
            // Cache the updated user data
            await prefs.setString('user_data', jsonEncode(_user!.toJson()));
            
            // Also update any user-specific fields in SharedPreferences for immediate access
            await prefs.setString('userName', _user!.fullName ?? '');
            await prefs.setString('userEmail', _user!.email ?? '');
            
            debugPrint("✅ Profile updated successfully: $responseBody");
            _setLoading(false);
            return true;
          } catch (e) {
            debugPrint("❌ Error parsing update response: $e");
            // Even if parsing fails, we'll still update our local user object
          }
        }
        
        // Update the user object with the edited fields
        _user = User(
          id: _user!.id,
          fullName: _editedFullName ?? _user!.fullName,
          email: _editedEmail ?? _user!.email,
          role: _user!.role,
          password: _user!.password,
          avatar: _user!.avatar,
          createdAt: _user!.createdAt,
          age: _editedAge ?? _user!.age,
          grade: _editedGrade ?? _user!.grade,
        );
        
        // Cache the updated user data
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        
        // Also update any user-specific fields in SharedPreferences for immediate access
        await prefs.setString('userName', _user!.fullName ?? '');
        await prefs.setString('userEmail', _user!.email ?? '');
        
        debugPrint("✅ Profile updated successfully (fallback path)");
        _setLoading(false);
        return true;
      } else if (response.statusCode == 401) {
        _errorMessage = "Session expirée - Veuillez vous reconnecter";
        debugPrint("❌ Authentication error: ${response.statusCode} - ${response.body}");
        _setLoading(false);
        return false;
      } else {
        _errorMessage = "Erreur ${response.statusCode}: ${response.body}";
        debugPrint("❌ Failed to update profile: ${response.statusCode} - ${response.body}");
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "Erreur réseau: $e";
      debugPrint("❌ Network error: $e");
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
  
  // Method to refresh user data from API
  Future<bool> refreshUserData() async {
    _user = null; // Clear cached user to force a fresh fetch
    final user = await getUserDetails();
    return user != null;
  }
}
