class ForgotPasswordResponse {
  final String message;
  final int userId;

  ForgotPasswordResponse({
    required this.message,
    required this.userId,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: json['message'],
      userId: json['userId'],
    );
  }
}