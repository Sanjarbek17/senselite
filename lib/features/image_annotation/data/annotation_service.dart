// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/annotation.dart';
import '../../../core/models/label.dart';
import '../../../core/database/annotation_dao.dart';
import '../../../core/database/image_dao.dart';
import '../presentation/widgets/annotation_canvas.dart';

/// Service for managing annotations in the image annotation feature
class AnnotationService {
  final AnnotationDao _annotationDao = AnnotationDao();
  final ImageDao _imageDao = ImageDao();
  final Uuid _uuid = const Uuid();

  /// Creates a new annotation from canvas drawing data
  Future<Annotation> createAnnotation({
    required String imageId,
    required String projectId,
    required Label label,
    required AnnotationTool tool,
    required List<Offset> canvasPoints,
    required Size imageSize,
    String? notes,
  }) async {
    final now = DateTime.now();
    final annotationId = _uuid.v4();

    // Convert canvas coordinates to normalized coordinates (0.0 to 1.0)
    final normalizedPoints = canvasPoints
        .map(
          (point) => Point(
            x: point.dx / imageSize.width,
            y: point.dy / imageSize.height,
          ),
        )
        .toList();

    Annotation annotation;

    switch (tool) {
      case AnnotationTool.boundingBox:
        if (canvasPoints.length < 2) {
          throw ArgumentError('Bounding box requires at least 2 points');
        }
        final topLeft = canvasPoints.first;
        final bottomRight = canvasPoints.last;

        final x = (topLeft.dx / imageSize.width).clamp(0.0, 1.0);
        final y = (topLeft.dy / imageSize.height).clamp(0.0, 1.0);
        final width = ((bottomRight.dx - topLeft.dx).abs() / imageSize.width).clamp(0.0, 1.0 - x);
        final height = ((bottomRight.dy - topLeft.dy).abs() / imageSize.height).clamp(0.0, 1.0 - y);

        annotation = BoundingBoxAnnotation(
          id: annotationId,
          labelId: label.id,
          imageId: imageId,
          projectId: projectId,
          createdAt: now,
          updatedAt: now,
          notes: notes,
          x: x,
          y: y,
          width: width,
          height: height,
        );
        break;

      case AnnotationTool.polygon:
        if (canvasPoints.length < 3) {
          throw ArgumentError('Polygon requires at least 3 points');
        }
        annotation = PolygonAnnotation(
          id: annotationId,
          labelId: label.id,
          imageId: imageId,
          projectId: projectId,
          createdAt: now,
          updatedAt: now,
          notes: notes,
          points: normalizedPoints,
        );
        break;

      case AnnotationTool.keypoint:
        if (canvasPoints.isEmpty) {
          throw ArgumentError('Keypoint annotation requires at least 1 point');
        }
        final keypoints = normalizedPoints
            .asMap()
            .entries
            .map(
              (entry) => Keypoint(
                name: 'keypoint_${entry.key + 1}',
                point: entry.value,
                visibility: 1, // 1 = visible
              ),
            )
            .toList();

        annotation = KeypointAnnotation(
          id: annotationId,
          labelId: label.id,
          imageId: imageId,
          projectId: projectId,
          createdAt: now,
          updatedAt: now,
          notes: notes,
          keypoints: keypoints,
        );
        break;

      case AnnotationTool.none:
        throw ArgumentError('Cannot create annotation with tool type "none"');
    }

    // Save to database
    await _annotationDao.insert(annotation);

    // Update image annotation status
    final annotationCount = await _annotationDao.getCountByImage(imageId);
    await _imageDao.updateAnnotationStatus(imageId, annotationCount > 0, annotationCount);

    return annotation;
  }

  /// Updates an existing annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    final updatedAnnotation = _copyAnnotationWithUpdatedTime(annotation);
    await _annotationDao.update(updatedAnnotation);
  }

  /// Deletes an annotation
  Future<void> deleteAnnotation(String annotationId, String imageId) async {
    await _annotationDao.delete(annotationId);

    // Update image annotation status
    final annotationCount = await _annotationDao.getCountByImage(imageId);
    await _imageDao.updateAnnotationStatus(imageId, annotationCount > 0, annotationCount);
  }

  /// Gets all annotations for an image
  Future<List<Annotation>> getAnnotationsForImage(String imageId) async {
    return await _annotationDao.getByImage(imageId);
  }

  /// Gets all annotations for a project
  Future<List<Annotation>> getAnnotationsForProject(String projectId) async {
    return await _annotationDao.getByProject(projectId);
  }

  /// Converts database annotation to canvas annotation
  CanvasAnnotation convertToCanvasAnnotation(Annotation annotation, Size imageSize) {
    List<Offset> canvasPoints;

    switch (annotation.type) {
      case AnnotationType.boundingBox:
        final bbox = annotation as BoundingBoxAnnotation;
        final topLeft = Offset(
          bbox.x * imageSize.width,
          bbox.y * imageSize.height,
        );
        final bottomRight = Offset(
          (bbox.x + bbox.width) * imageSize.width,
          (bbox.y + bbox.height) * imageSize.height,
        );
        canvasPoints = [topLeft, bottomRight];
        break;

      case AnnotationType.polygon:
        final polygon = annotation as PolygonAnnotation;
        canvasPoints = polygon.points
            .map(
              (point) => Offset(
                point.x * imageSize.width,
                point.y * imageSize.height,
              ),
            )
            .toList();
        break;

      case AnnotationType.keypoint:
        final keypoints = annotation as KeypointAnnotation;
        canvasPoints = keypoints.keypoints
            .map(
              (kp) => Offset(
                kp.point.x * imageSize.width,
                kp.point.y * imageSize.height,
              ),
            )
            .toList();
        break;
    }

    return CanvasAnnotation(
      id: annotation.id,
      tool: _annotationTypeToTool(annotation.type),
      points: canvasPoints,
    );
  }

  /// Converts annotation type to annotation tool
  AnnotationTool _annotationTypeToTool(AnnotationType type) {
    switch (type) {
      case AnnotationType.boundingBox:
        return AnnotationTool.boundingBox;
      case AnnotationType.polygon:
        return AnnotationTool.polygon;
      case AnnotationType.keypoint:
        return AnnotationTool.keypoint;
    }
  }

  /// Creates a copy of annotation with updated timestamp
  Annotation _copyAnnotationWithUpdatedTime(Annotation annotation) {
    final now = DateTime.now();

    switch (annotation.type) {
      case AnnotationType.boundingBox:
        return (annotation as BoundingBoxAnnotation).copyWith(updatedAt: now);
      case AnnotationType.polygon:
        return (annotation as PolygonAnnotation).copyWith(updatedAt: now);
      case AnnotationType.keypoint:
        return (annotation as KeypointAnnotation).copyWith(updatedAt: now);
    }
  }
}
