class ChangePasswordRequest {
  final String password;

  ChangePasswordRequest({required this.password});

  Map<String, dynamic> toJson() {
    return {
      'password': password,
    };
  }
}

class ChangePasswordResponse {
  final String message;

  ChangePasswordResponse({required this.message});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      message: json['message'] ?? '',
    );
  }
}