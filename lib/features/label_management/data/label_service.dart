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
import '../../../core/models/label.dart';
import '../../../core/database/label_dao.dart';
import '../../../core/database/annotation_dao.dart';
import '../../../core/constants/app_constants.dart';

/// Service for managing labels
class LabelService {
  final LabelDao _labelDao = LabelDao();
  final AnnotationDao _annotationDao = AnnotationDao();
  final Uuid _uuid = const Uuid();

  /// Creates a new label
  Future<Label> createLabel({
    required String name,
    required Color color,
    required String projectId,
    String? description,
    String? shortcut,
  }) async {
    // Validate name length
    if (name.length > AppConstants.maxLabelNameLength) {
      throw ArgumentError('Label name too long');
    }

    // Check if name is unique in project
    final isUnique = await _labelDao.isNameUnique(projectId, name);
    if (!isUnique) {
      throw ArgumentError('Label name already exists in this project');
    }

    // Check if shortcut is unique (if provided)
    if (shortcut != null && shortcut.isNotEmpty) {
      final existingLabel = await _labelDao.getByShortcut(projectId, shortcut);
      if (existingLabel != null) {
        throw ArgumentError('Shortcut already exists in this project');
      }
    }

    final label = Label(
      id: _uuid.v4(),
      name: name.trim(),
      color: color,
      projectId: projectId,
      description: description?.trim(),
      shortcut: shortcut?.trim(),
      annotationCount: 0,
      createdAt: DateTime.now(),
    );

    await _labelDao.insert(label);
    return label;
  }

  /// Updates an existing label
  Future<Label> updateLabel(Label label) async {
    // Validate name length
    if (label.name.length > AppConstants.maxLabelNameLength) {
      throw ArgumentError('Label name too long');
    }

    // Check if name is unique in project (excluding current label)
    final isUnique = await _labelDao.isNameUnique(
      label.projectId,
      label.name,
      excludeId: label.id,
    );
    if (!isUnique) {
      throw ArgumentError('Label name already exists in this project');
    }

    // Check if shortcut is unique (if provided, excluding current label)
    if (label.shortcut != null && label.shortcut!.isNotEmpty) {
      final existingLabel = await _labelDao.getByShortcut(label.projectId, label.shortcut!);
      if (existingLabel != null && existingLabel.id != label.id) {
        throw ArgumentError('Shortcut already exists in this project');
      }
    }

    await _labelDao.update(label);
    return label;
  }

  /// Deletes a label
  Future<void> deleteLabel(String labelId) async {
    // Check if label has annotations
    final annotationCount = await _annotationDao.getCountByLabel(labelId);
    if (annotationCount > 0) {
      throw StateError('Cannot delete label with existing annotations');
    }

    await _labelDao.delete(labelId);
  }

  /// Gets a label by ID
  Future<Label?> getLabel(String labelId) async {
    return await _labelDao.getById(labelId);
  }

  /// Gets all labels for a project
  Future<List<Label>> getProjectLabels(String projectId) async {
    return await _labelDao.getByProject(projectId);
  }

  /// Searches labels by name
  Future<List<Label>> searchLabels(String projectId, String query) async {
    if (query.trim().isEmpty) {
      return await getProjectLabels(projectId);
    }
    return await _labelDao.searchByName(projectId, query.trim());
  }

  /// Gets label by shortcut
  Future<Label?> getLabelByShortcut(String projectId, String shortcut) async {
    return await _labelDao.getByShortcut(projectId, shortcut);
  }

  /// Updates annotation count for a label
  Future<void> updateAnnotationCount(String labelId) async {
    final count = await _annotationDao.getCountByLabel(labelId);
    await _labelDao.updateAnnotationCount(labelId, count);
  }

  /// Gets next available shortcut number for a project
  Future<String?> getNextAvailableShortcut(String projectId) async {
    final labels = await getProjectLabels(projectId);
    final usedShortcuts = labels.where((label) => label.shortcut != null).map((label) => label.shortcut!).toSet();

    for (int i = 1; i <= 9; i++) {
      final shortcut = i.toString();
      if (!usedShortcuts.contains(shortcut)) {
        return shortcut;
      }
    }

    return null; // All shortcuts 1-9 are used
  }

  /// Gets project label statistics
  Future<Map<String, dynamic>> getLabelStatistics(String projectId) async {
    final labels = await getProjectLabels(projectId);
    int totalAnnotations = 0;

    for (final label in labels) {
      totalAnnotations += label.annotationCount;
    }

    return {
      'totalLabels': labels.length,
      'totalAnnotations': totalAnnotations,
      'labelsWithAnnotations': labels.where((l) => l.annotationCount > 0).length,
      'averageAnnotationsPerLabel': labels.isEmpty ? 0.0 : totalAnnotations / labels.length,
    };
  }
}
