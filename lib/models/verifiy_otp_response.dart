class OtpVerificationRequest {
  final String otp;

  OtpVerificationRequest({required this.otp});

  Map<String, dynamic> toJson() {
    return {
      'otp': otp,
    };
  }
}

class OtpVerificationResponse {
  final String message;

  OtpVerificationResponse({required this.message});

  factory OtpVerificationResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerificationResponse(
      message: json['message'] ?? '',
    );
  }
}