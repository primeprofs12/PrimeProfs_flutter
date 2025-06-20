import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiiService {
  static const String baseUrl =
      'http://10.0.2.2:11434/api/chat'; // Pour l'émulateur Android Studio

  Future<String> sendPrompt(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'mon-modele-education',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': false,
          'options': {'num_ctx': 512},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'];
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête: $e');
    }
  }
}
