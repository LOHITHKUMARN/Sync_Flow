import 'package:flutter/material.dart';

class TaskLabel {
  final String id;
  final String name;
  final String colorHex;

  const TaskLabel({
    required this.id,
    required this.name,
    this.colorHex = '#6366F1',
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('0xFF$hex'));
  }


  factory TaskLabel.fromJson(Map<String, dynamic> json) {
    return TaskLabel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      colorHex: json['color_hex'] as String? ?? json['color'] as String? ?? '#6366F1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
    };
  }

  TaskLabel copyWith({
    String? id,
    String? name,
    String? colorHex,
  }) {
    return TaskLabel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskLabel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
