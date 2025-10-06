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

part 'project.g.dart';

/// Represents a SenseLite annotation project containing images and annotations
@JsonSerializable()
class Project {
  /// Unique identifier for the project
  final String id;

  /// Human-readable name of the project
  final String name;

  /// Optional description of the project
  final String? description;

  /// Absolute path to the project directory
  final String projectPath;

  /// Absolute path to the images directory
  final String imagesPath;

  /// Timestamp when the project was created
  final DateTime createdAt;

  /// Timestamp when the project was last modified
  final DateTime updatedAt;

  /// Total number of images in the project
  final int totalImages;

  /// Number of images that have been annotated
  final int annotatedImages;

  /// Creates a new Project instance
  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.projectPath,
    required this.imagesPath,
    required this.createdAt,
    required this.updatedAt,
    this.totalImages = 0,
    this.annotatedImages = 0,
  });

  /// Creates a Project from JSON data
  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

  /// Converts the Project to JSON
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  /// Creates a copy of this Project with updated fields
  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? projectPath,
    String? imagesPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalImages,
    int? annotatedImages,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      projectPath: projectPath ?? this.projectPath,
      imagesPath: imagesPath ?? this.imagesPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalImages: totalImages ?? this.totalImages,
      annotatedImages: annotatedImages ?? this.annotatedImages,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Project(id: $id, name: $name, totalImages: $totalImages, annotatedImages: $annotatedImages)';
  }
}
