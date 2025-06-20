import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/change_password_model.dart';

class ChangePasswordViewModel {
  Future<ChangePasswordResponse> changePassword(String userId, String password) async {
    try {
      // Prepare the request body
      final request = ChangePasswordRequest(password: password);
      final requestBody = request.toJson();

      // Use the endpoint from AppConfig
      final url = '${AppConfig.changePasswordUrl}/$userId';

      // Make the POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Handle the response
      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return ChangePasswordResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; // Rethrow the exception so it can be handled by the UI
    }
  }
}