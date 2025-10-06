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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/label.dart';
import '../../features/label_management/data/label_service.dart';

/// Provider for LabelService
final labelServiceProvider = Provider<LabelService>((ref) {
  return LabelService();
});

/// Provider for project labels
final projectLabelsProvider = FutureProvider.family<List<Label>, String>((ref, projectId) async {
  final labelService = ref.watch(labelServiceProvider);
  return await labelService.getProjectLabels(projectId);
});

/// Provider for label statistics
final labelStatisticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  final labelService = ref.watch(labelServiceProvider);
  return await labelService.getLabelStatistics(projectId);
});

/// Provider for searching labels
final labelSearchProvider = FutureProvider.family<List<Label>, Map<String, String>>((ref, params) async {
  final labelService = ref.watch(labelServiceProvider);
  final projectId = params['projectId']!;
  final query = params['query'] ?? '';
  return await labelService.searchLabels(projectId, query);
});

/// State notifier for managing project labels
class ProjectLabelsNotifier extends StateNotifier<List<Label>> {
  final LabelService _labelService;
  final String _projectId;
  bool _isLoading = false;

  ProjectLabelsNotifier(this._labelService, this._projectId) : super([]);

  /// Whether the provider is loading
  bool get isLoading => _isLoading;

  /// Loads all labels for the project
  Future<void> loadLabels() async {
    _isLoading = true;
    try {
      final labels = await _labelService.getProjectLabels(_projectId);
      state = labels;
    } catch (e) {
      state = [];
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Adds a new label
  Future<Label> addLabel({
    required String name,
    required Color color,
    String? description,
    String? shortcut,
  }) async {
    try {
      final label = await _labelService.createLabel(
        name: name,
        color: color,
        projectId: _projectId,
        description: description,
        shortcut: shortcut,
      );
      state = [...state, label];
      return label;
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing label
  Future<Label> updateLabel(Label updatedLabel) async {
    try {
      final label = await _labelService.updateLabel(updatedLabel);
      state = state.map((l) => l.id == label.id ? label : l).toList();
      return label;
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a label
  Future<void> deleteLabel(String labelId) async {
    try {
      await _labelService.deleteLabel(labelId);
      state = state.where((label) => label.id != labelId).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Refreshes labels from database
  Future<void> refresh() async {
    await loadLabels();
  }

  /// Gets next available shortcut
  Future<String?> getNextAvailableShortcut() async {
    return await _labelService.getNextAvailableShortcut(_projectId);
  }

  /// Updates annotation count for a label
  Future<void> updateAnnotationCount(String labelId) async {
    await _labelService.updateAnnotationCount(labelId);
    // Refresh to get updated counts
    await refresh();
  }
}

/// Provider for project labels notifier
final projectLabelsNotifierProvider = StateNotifierProvider.family<ProjectLabelsNotifier, List<Label>, String>((ref, projectId) {
  final labelService = ref.watch(labelServiceProvider);
  return ProjectLabelsNotifier(labelService, projectId);
});

/// State notifier for the currently selected label
class SelectedLabelNotifier extends StateNotifier<Label?> {
  SelectedLabelNotifier() : super(null);

  /// Sets the selected label
  void selectLabel(Label? label) {
    state = label;
  }

  /// Clears the selected label
  void clearSelection() {
    state = null;
  }

  /// Updates the selected label if it matches the given label
  void updateLabel(Label updatedLabel) {
    if (state?.id == updatedLabel.id) {
      state = updatedLabel;
    }
  }
}

/// Provider for the currently selected label
final selectedLabelProvider = StateNotifierProvider<SelectedLabelNotifier, Label?>((ref) {
  return SelectedLabelNotifier();
});

/// Provider for getting a label by ID
final labelByIdProvider = FutureProvider.family<Label?, String>((ref, labelId) async {
  final labelService = ref.watch(labelServiceProvider);
  return await labelService.getLabel(labelId);
});

/// Provider for getting a label by shortcut
final labelByShortcutProvider = FutureProvider.family<Label?, Map<String, String>>((ref, params) async {
  final labelService = ref.watch(labelServiceProvider);
  final projectId = params['projectId']!;
  final shortcut = params['shortcut']!;
  return await labelService.getLabelByShortcut(projectId, shortcut);
});
