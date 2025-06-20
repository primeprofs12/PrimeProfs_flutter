import 'dart:developer' as developer;

class Fiche {
  final String id;
  final String title;
  final String attachment;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final Map<String, dynamic>? chapter;

  Fiche({
    required this.id,
    required this.title,
    required this.attachment,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.chapter,
  });

  factory Fiche.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      developer.log('Erreur : Fiche JSON est null');
      throw Exception('Fiche JSON est null');
    }

    developer.log('Parsing fiche from JSON: $json');

    return Fiche(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sans titre',
      attachment: json['attachment'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      deletedAt: json['deletedAt'] as String?,
      chapter: json['chapter'] != null
          ? Map<String, dynamic>.from(json['chapter'])
          : null,
    );
  }
}
