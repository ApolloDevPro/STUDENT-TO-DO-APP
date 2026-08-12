import 'dart:ui';

class Subject {
  final String id;
  String name;
  String code;
  int colorValue;
  DateTime updatedAt;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.colorValue,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'colorValue': colorValue,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Subject.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now();
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      colorValue: json['colorValue'] as int,
      updatedAt: updatedAt,
    );
  }
}
