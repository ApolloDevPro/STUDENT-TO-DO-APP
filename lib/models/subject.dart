import 'dart:ui';

class Subject {
  final String id;
  String name;
  String code;
  int colorValue;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'colorValue': colorValue,
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'],
    name: json['name'],
    code: json['code'],
    colorValue: json['colorValue'],
  );
}