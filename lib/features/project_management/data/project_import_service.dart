// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/models/annotation.dart';
import '../../../../core/models/label.dart';

/// Data structure for imported project data
class ImportedProjectData {
  final List<Label> labels;
  final List<Annotation> annotations;
  final Map<String, dynamic>? metadata;

  const ImportedProjectData({
    required this.labels,
    required this.annotations,
    this.metadata,
  });
}

/// Service for importing project data from various formats
class ProjectImportService {
  /// Import project data from a JSON file
  Future<ImportedProjectData?> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('File not found', filePath);
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Parse labels
      final labelsList = data['labels'] as List<dynamic>? ?? [];
      final labels = labelsList.map((labelData) {
        return Label.fromJson(labelData as Map<String, dynamic>);
      }).toList();

      // Parse annotations
      final annotationsList = data['annotations'] as List<dynamic>? ?? [];
      final annotations = annotationsList.map((annotationData) {
        return Annotation.fromJson(annotationData as Map<String, dynamic>);
      }).toList();

      return ImportedProjectData(
        labels: labels,
        annotations: annotations,
        metadata: data['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw Exception('Failed to import JSON file: $e');
    }
  }

  /// Import project data from COCO format
  Future<ImportedProjectData?> importFromCoco(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw FileSystemException('File not found', filePath);
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Parse COCO categories as labels
      final categories = data['categories'] as List<dynamic>? ?? [];
      final labels = <Label>[];

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i] as Map<String, dynamic>;
        labels.add(
          Label(
            id: 'imported_label_${category['id']}',
            name: category['name'] as String,
            color: Color(0xFF2196F3), // Default blue color
            projectId: 'temp_project', // Will be updated when project is created
            createdAt: DateTime.now(),
          ),
        );
      }

      // Parse COCO annotations
      final cocoAnnotations = data['annotations'] as List<dynamic>? ?? [];
      final annotations = <Annotation>[];

      for (final cocoAnnotation in cocoAnnotations) {
        final annotationData = cocoAnnotation as Map<String, dynamic>;
        final categoryId = annotationData['category_id'] as int;
        final labelId = 'imported_label_$categoryId';

        // Convert COCO bbox format [x, y, width, height] to our format
        if (annotationData.containsKey('bbox')) {
          final bbox = annotationData['bbox'] as List<dynamic>;
          annotations.add(
            BoundingBoxAnnotation(
              id: 'imported_annotation_${annotationData['id']}',
              labelId: labelId,
              imageId: 'imported_image_${annotationData['image_id']}',
              projectId: 'temp_project',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              x: (bbox[0] as num).toDouble(),
              y: (bbox[1] as num).toDouble(),
              width: (bbox[2] as num).toDouble(),
              height: (bbox[3] as num).toDouble(),
            ),
          );
        }

        // Convert COCO segmentation to polygon if available
        if (annotationData.containsKey('segmentation')) {
          final segmentation = annotationData['segmentation'] as List<dynamic>;
          if (segmentation.isNotEmpty && segmentation[0] is List) {
            final coords = segmentation[0] as List<dynamic>;
            final points = <Point>[];

            for (int i = 0; i < coords.length; i += 2) {
              if (i + 1 < coords.length) {
                points.add(
                  Point(
                    x: (coords[i] as num).toDouble(),
                    y: (coords[i + 1] as num).toDouble(),
                  ),
                );
              }
            }

            if (points.length >= 3) {
              annotations.add(
                PolygonAnnotation(
                  id: 'imported_polygon_${annotationData['id']}',
                  labelId: labelId,
                  imageId: 'imported_image_${annotationData['image_id']}',
                  projectId: 'temp_project',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  points: points,
                ),
              );
            }
          }
        }
      }

      return ImportedProjectData(
        labels: labels,
        annotations: annotations,
        metadata: {
          'format': 'COCO',
          'info': data['info'],
          'images': data['images'],
        },
      );
    } catch (e) {
      throw Exception('Failed to import COCO file: $e');
    }
  }

  /// Import project data from Pascal VOC format
  Future<ImportedProjectData?> importFromPascalVoc(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!directory.existsSync()) {
        throw FileSystemException('Directory not found', directoryPath);
      }

      // For Pascal VOC, we would need to parse XML files
      // This is a simplified implementation - in reality, you'd parse XML annotation files

      final labels = <Label>[
        Label(
          id: 'imported_label_person',
          name: 'person',
          color: const Color(0xFF2196F3),
          projectId: 'temp_project',
          createdAt: DateTime.now(),
        ),
        Label(
          id: 'imported_label_car',
          name: 'car',
          color: const Color(0xFFFF5722),
          projectId: 'temp_project',
          createdAt: DateTime.now(),
        ),
      ];

      // This would be replaced with actual XML parsing logic
      final annotations = <Annotation>[];

      return ImportedProjectData(
        labels: labels,
        annotations: annotations,
        metadata: {
          'format': 'Pascal VOC',
          'directory': directoryPath,
        },
      );
    } catch (e) {
      throw Exception('Failed to import Pascal VOC directory: $e');
    }
  }

  /// Auto-detect format and import
  Future<ImportedProjectData?> autoImport(String path) async {
    final file = File(path);

    if (file.existsSync()) {
      final extension = path.toLowerCase().split('.').last;

      switch (extension) {
        case 'json':
          // Try to detect if it's COCO format by checking for specific keys
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;

          if (data.containsKey('categories') && data.containsKey('annotations')) {
            return await importFromCoco(path);
          } else {
            return await importFromJson(path);
          }
        default:
          throw Exception('Unsupported file format: $extension');
      }
    } else {
      final directory = Directory(path);
      if (directory.existsSync()) {
        return await importFromPascalVoc(path);
      } else {
        throw Exception('Path does not exist: $path');
      }
    }
  }
}
