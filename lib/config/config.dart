class AppConfig {
  static const String baseUrl = 'http://127.0.0.1:3000';


  // Existing endpoints
  static const String loginUrl = '$baseUrl/auth/login';
  static const String userProfileUrl = '$baseUrl/auth/profile';
  static const String forgotPasswordUrl = '$baseUrl/auth/forgot-password';
  static const String verifyOtpUrl = '$baseUrl/auth/verify-otp';
  static const String changePasswordUrl = '$baseUrl/auth/reset-password';
  static const String chatHistoryUrl = '$baseUrl/chat/history';
  static const String conversationsUrl = '$baseUrl/chat/conversations';
  static const String messagesUrl = '$baseUrl/chat/message';
  static const String markReadUrl = '$baseUrl/chat/mark-as-read';

  // Reservation endpoints
  static const String reserveCourseUrl = '$baseUrl/reservations/reserve';
  static const String cancelCourseUrl = '$baseUrl/reservations/cancel';
  static const String userReservationsUrl = '$baseUrl/reservations';

  // AI agent endpoint
  static const String chatUrl = '$baseUrl';
  


  static const String coursesByDateUrl =
      '$baseUrl/reservations/courses-by-date';
  static const String reservedCoursesUrl =
      '$baseUrl/reservations/reserved-courses';

  // FAQ endpoints
  static const String faqReportUrl = '$baseUrl/faq/report';
  static const String faqReportsUrl = '$baseUrl/faq/reports';
}



//      'http://127.0.0.1:3000'; // IP ta3 daly 
