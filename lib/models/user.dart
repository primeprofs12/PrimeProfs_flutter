class User {
  final int? id;
  final String? fullName; // Rendu nullable
  final String? email; // Rendu nullable
  final String? role; // Rendu nullable
  final String? password; // Rendu nullable
  final String? avatar; // Déjà nullable
  final String? createdAt; // Rendu nullable
  final int? age; // Rendu nullable
  final String? grade; // Rendu nullable
  final int? packHours; 

  User({
    this.id,
    this.fullName,
    this.email,
    this.role,
    this.password,
    this.avatar,
    this.createdAt,
    this.age,
    this.grade,
    this.packHours,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?, // Cast sécurisé
      fullName: json['fullName'] as String?, // Cast sécurisé
      email: json['email'] as String?, // Cast sécurisé
      role: json['role'] as String?, // Cast sécurisé
      password: json['password'] as String?, // Cast sécurisé
      avatar: json['avatar'] as String?, // Cast sécurisé
      createdAt: json['createdAt'] as String?, // Cast sécurisé
      age: json['age'] as int?, // Cast sécurisé
      grade: json['grade'] as String?, // Cast sécurisé
      packHours: json['packHours'] as int?, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'password': password,
      'avatar': avatar,
      'createdAt': createdAt,
      'age': age,
      'grade': grade,
      'packHours': packHours, 
    };
  }

  get profilePicture => avatar;
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int userId;
  late final String? sessionId; // Nullable for backward compatibility
  final String? role;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.sessionId,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      userId: json['userId'],
      sessionId: json['sessionId'] as String?, // Nullable
      role: json['role'] as String?, // Nullable
    );
  }
}
