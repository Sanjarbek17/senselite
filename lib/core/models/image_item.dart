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

part 'image_item.g.dart';

/// Represents an image file in the annotation project
@JsonSerializable()
class ImageItem {
  /// Unique identifier for the image
  final String id;

  /// Original filename of the image
  final String filename;

  /// Absolute path to the image file
  final String filePath;

  /// Width of the image in pixels
  final int width;

  /// Height of the image in pixels
  final int height;

  /// File size in bytes
  final int fileSize;

  /// Project ID this image belongs to
  final String projectId;

  /// Whether this image has been annotated
  final bool isAnnotated;

  /// Number of annotations on this image
  final int annotationCount;

  /// Timestamp when the image was added to the project
  final DateTime addedAt;

  /// Creates a new ImageItem instance
  const ImageItem({
    required this.id,
    required this.filename,
    required this.filePath,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.projectId,
    this.isAnnotated = false,
    this.annotationCount = 0,
    required this.addedAt,
  });

  /// Creates an ImageItem from JSON data
  factory ImageItem.fromJson(Map<String, dynamic> json) => _$ImageItemFromJson(json);

  /// Converts the ImageItem to JSON
  Map<String, dynamic> toJson() => _$ImageItemToJson(this);

  /// Creates a copy of this ImageItem with updated fields
  ImageItem copyWith({
    String? id,
    String? filename,
    String? filePath,
    int? width,
    int? height,
    int? fileSize,
    String? projectId,
    bool? isAnnotated,
    int? annotationCount,
    DateTime? addedAt,
  }) {
    return ImageItem(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      filePath: filePath ?? this.filePath,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      projectId: projectId ?? this.projectId,
      isAnnotated: isAnnotated ?? this.isAnnotated,
      annotationCount: annotationCount ?? this.annotationCount,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ImageItem(id: $id, filename: $filename, isAnnotated: $isAnnotated)';
  }
}
