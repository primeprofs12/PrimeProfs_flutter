import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/verifiy_otp_response.dart';

class OtpVerificationViewModel extends ChangeNotifier {
  Future<OtpVerificationResponse> verifyOtp(String otp) async {
    try {
      // Prepare the request body
      final request = OtpVerificationRequest(otp: otp);
      final requestBody = request.toJson();
      // Make the POST request
      final response = await http.post(
        Uri.parse(AppConfig.verifyOtpUrl), // Use AppConfig.verifyOtpUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      // Handle the response
      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return OtpVerificationResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; // Rethrow the exception so it can be handled by the UI
    }
  }
}