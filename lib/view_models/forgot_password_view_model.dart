import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import '../models/forgot_password_response.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  Future<ForgotPasswordResponse?> forgotPassword(String email) async {

    try {
      final response = await http.post(
        Uri.parse(AppConfig.forgotPasswordUrl), // Use AppConfig.forgotPasswordUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return ForgotPasswordResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to send forgot password request');
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
