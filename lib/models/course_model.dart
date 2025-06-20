import 'dart:developer' as developer;

class CourseModel {
  final int? studentId;
  final int teacherId;
  final String date;
  final String startTime;
  final int duration;
  final String? status; // From your NestJS service (e.g., 'confirmed', 'cancelled')
  final int? id; // Added for retrieved courses

  CourseModel({
    this.studentId, // Optional as in DTO
    required this.teacherId,
    required this.date,
    required this.startTime,
    required this.duration,
    this.status,
    this.id,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      developer.log('Erreur : Course JSON est null');
      throw Exception('Course JSON est null');
    }

    developer.log('Parsing course from JSON: $json');

    return CourseModel(
      studentId: json['studentId'] as int?, // Nullable, no default
      teacherId: json['teacherId'] as int? ?? 0, // Default to 0 if null
      date: json['date'] as String? ?? '', // Default to empty string
      startTime: json['startTime'] as String? ?? '', // Default to empty string
      duration: json['duration'] as int? ?? 0, // Default to 0 if null
      status: json['status'] as String?, // Nullable, no default
      id: json['id'] as int?, // Nullable, no default
    );
  }
}