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

part 'annotation.g.dart';

/// Types of annotations supported
enum AnnotationType {
  boundingBox,
  polygon,
  keypoint,
}

/// Base class for all annotation types
abstract class Annotation {
  /// Unique identifier for the annotation
  final String id;

  /// Type of annotation
  final AnnotationType type;

  /// Label ID associated with this annotation
  final String labelId;

  /// Image ID this annotation belongs to
  final String imageId;

  /// Project ID this annotation belongs to
  final String projectId;

  /// Timestamp when the annotation was created
  final DateTime createdAt;

  /// Timestamp when the annotation was last modified
  final DateTime updatedAt;

  /// Optional notes for this annotation
  final String? notes;

  /// Creates a new Annotation instance
  const Annotation({
    required this.id,
    required this.type,
    required this.labelId,
    required this.imageId,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /// Creates an Annotation from JSON data
  factory Annotation.fromJson(Map<String, dynamic> json) {
    final type = AnnotationType.values.byName(json['type'] as String);
    switch (type) {
      case AnnotationType.boundingBox:
        return BoundingBoxAnnotation.fromJson(json);
      case AnnotationType.polygon:
        return PolygonAnnotation.fromJson(json);
      case AnnotationType.keypoint:
        return KeypointAnnotation.fromJson(json);
    }
  }

  /// Converts the Annotation to JSON
  Map<String, dynamic> toJson();
}

/// Represents a point with x and y coordinates
@JsonSerializable()
class Point {
  /// X coordinate (normalized 0.0 to 1.0)
  final double x;

  /// Y coordinate (normalized 0.0 to 1.0)
  final double y;

  /// Creates a new Point instance
  const Point({
    required this.x,
    required this.y,
  });

  /// Creates a Point from JSON data
  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);

  /// Converts the Point to JSON
  Map<String, dynamic> toJson() => _$PointToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Point(x: $x, y: $y)';
}

/// Represents a bounding box annotation
@JsonSerializable()
class BoundingBoxAnnotation extends Annotation {
  /// Top-left x coordinate (normalized 0.0 to 1.0)
  final double x;

  /// Top-left y coordinate (normalized 0.0 to 1.0)
  final double y;

  /// Width of the bounding box (normalized 0.0 to 1.0)
  final double width;

  /// Height of the bounding box (normalized 0.0 to 1.0)
  final double height;

  /// Creates a new BoundingBoxAnnotation instance
  const BoundingBoxAnnotation({
    required super.id,
    required super.labelId,
    required super.imageId,
    required super.projectId,
    required super.createdAt,
    required super.updatedAt,
    super.notes,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  }) : super(type: AnnotationType.boundingBox);

  /// Creates a BoundingBoxAnnotation from JSON data
  factory BoundingBoxAnnotation.fromJson(Map<String, dynamic> json) => _$BoundingBoxAnnotationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BoundingBoxAnnotationToJson(this);

  /// Creates a copy of this BoundingBoxAnnotation with updated fields
  BoundingBoxAnnotation copyWith({
    String? id,
    String? labelId,
    String? imageId,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return BoundingBoxAnnotation(
      id: id ?? this.id,
      labelId: labelId ?? this.labelId,
      imageId: imageId ?? this.imageId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String toString() {
    return 'BoundingBoxAnnotation(id: $id, x: $x, y: $y, width: $width, height: $height)';
  }
}

/// Represents a polygon annotation
@JsonSerializable()
class PolygonAnnotation extends Annotation {
  /// List of points defining the polygon
  final List<Point> points;

  /// Creates a new PolygonAnnotation instance
  const PolygonAnnotation({
    required super.id,
    required super.labelId,
    required super.imageId,
    required super.projectId,
    required super.createdAt,
    required super.updatedAt,
    super.notes,
    required this.points,
  }) : super(type: AnnotationType.polygon);

  /// Creates a PolygonAnnotation from JSON data
  factory PolygonAnnotation.fromJson(Map<String, dynamic> json) => _$PolygonAnnotationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PolygonAnnotationToJson(this);

  /// Creates a copy of this PolygonAnnotation with updated fields
  PolygonAnnotation copyWith({
    String? id,
    String? labelId,
    String? imageId,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    List<Point>? points,
  }) {
    return PolygonAnnotation(
      id: id ?? this.id,
      labelId: labelId ?? this.labelId,
      imageId: imageId ?? this.imageId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      points: points ?? this.points,
    );
  }

  @override
  String toString() {
    return 'PolygonAnnotation(id: $id, points: ${points.length})';
  }
}

/// Represents a keypoint annotation
@JsonSerializable()
class KeypointAnnotation extends Annotation {
  /// List of keypoints
  final List<Keypoint> keypoints;

  /// Creates a new KeypointAnnotation instance
  const KeypointAnnotation({
    required super.id,
    required super.labelId,
    required super.imageId,
    required super.projectId,
    required super.createdAt,
    required super.updatedAt,
    super.notes,
    required this.keypoints,
  }) : super(type: AnnotationType.keypoint);

  /// Creates a KeypointAnnotation from JSON data
  factory KeypointAnnotation.fromJson(Map<String, dynamic> json) => _$KeypointAnnotationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$KeypointAnnotationToJson(this);

  /// Creates a copy of this KeypointAnnotation with updated fields
  KeypointAnnotation copyWith({
    String? id,
    String? labelId,
    String? imageId,
    String? projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    List<Keypoint>? keypoints,
  }) {
    return KeypointAnnotation(
      id: id ?? this.id,
      labelId: labelId ?? this.labelId,
      imageId: imageId ?? this.imageId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      keypoints: keypoints ?? this.keypoints,
    );
  }

  @override
  String toString() {
    return 'KeypointAnnotation(id: $id, keypoints: ${keypoints.length})';
  }
}

/// Represents a single keypoint
@JsonSerializable()
class Keypoint {
  /// Name of the keypoint (e.g., "left_eye", "nose")
  final String name;

  /// Position of the keypoint
  final Point point;

  /// Visibility of the keypoint (0 = not visible, 1 = visible, 2 = occluded)
  final int visibility;

  /// Creates a new Keypoint instance
  const Keypoint({
    required this.name,
    required this.point,
    this.visibility = 1,
  });

  /// Creates a Keypoint from JSON data
  factory Keypoint.fromJson(Map<String, dynamic> json) => _$KeypointFromJson(json);

  /// Converts the Keypoint to JSON
  Map<String, dynamic> toJson() => _$KeypointToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Keypoint && other.name == name && other.point == point && other.visibility == visibility;
  }

  @override
  int get hashCode => name.hashCode ^ point.hashCode ^ visibility.hashCode;

  @override
  String toString() => 'Keypoint(name: $name, point: $point, visibility: $visibility)';
}
