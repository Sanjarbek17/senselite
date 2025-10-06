// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'label.g.dart';

/// Represents a label class for annotations
@JsonSerializable()
class Label {
  /// Unique identifier for the label
  final String id;

  /// Name of the label (e.g., "person", "car", "dog")
  final String name;

  /// Color used to display this label
  @ColorConverter()
  final Color color;

  /// Project ID this label belongs to
  final String projectId;

  /// Optional description of the label
  final String? description;

  /// Keyboard shortcut for quick selection
  final String? shortcut;

  /// Number of annotations using this label
  final int annotationCount;

  /// Timestamp when the label was created
  final DateTime createdAt;

  /// Creates a new Label instance
  const Label({
    required this.id,
    required this.name,
    required this.color,
    required this.projectId,
    this.description,
    this.shortcut,
    this.annotationCount = 0,
    required this.createdAt,
  });

  /// Creates a Label from JSON data
  factory Label.fromJson(Map<String, dynamic> json) => _$LabelFromJson(json);

  /// Converts the Label to JSON
  Map<String, dynamic> toJson() => _$LabelToJson(this);

  /// Creates a copy of this Label with updated fields
  Label copyWith({
    String? id,
    String? name,
    Color? color,
    String? projectId,
    String? description,
    String? shortcut,
    int? annotationCount,
    DateTime? createdAt,
  }) {
    return Label(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      projectId: projectId ?? this.projectId,
      description: description ?? this.description,
      shortcut: shortcut ?? this.shortcut,
      annotationCount: annotationCount ?? this.annotationCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Label && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Label(id: $id, name: $name, color: $color)';
  }
}

/// Custom converter for Color to JSON
class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color object) => object.value;
}
