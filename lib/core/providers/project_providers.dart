// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/image_item.dart';
import '../../features/project_management/data/project_service.dart';

/// Provider for ProjectService
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

/// Provider for the current active project
final currentProjectProvider = StateNotifierProvider<CurrentProjectNotifier, Project?>((ref) {
  return CurrentProjectNotifier(ref.watch(projectServiceProvider));
});

/// Provider for project list management
final projectListProvider = StateNotifierProvider<ProjectListNotifier, List<Project>>((ref) {
  return ProjectListNotifier(ref.watch(projectServiceProvider));
});

/// Provider for all projects
final allProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final projectService = ref.watch(projectServiceProvider);
  return await projectService.getAllProjects();
});

/// Provider for recent projects
final recentProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final projectService = ref.watch(projectServiceProvider);
  return await projectService.getRecentProjects();
});

/// Provider for project images
final projectImagesProvider = FutureProvider.family<List<ImageItem>, String>((ref, projectId) async {
  final projectService = ref.watch(projectServiceProvider);
  return await projectService.getProjectImages(projectId);
});

/// Provider for project statistics
final projectStatisticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  final projectService = ref.watch(projectServiceProvider);
  return await projectService.getProjectStatistics(projectId);
});

/// State notifier for the current project
class CurrentProjectNotifier extends StateNotifier<Project?> {
  final ProjectService _projectService;

  CurrentProjectNotifier(this._projectService) : super(null);

  /// Loads a project by ID
  Future<void> loadProject(String projectId) async {
    try {
      final project = await _projectService.loadProject(projectId);
      state = project;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  /// Sets the current project
  void setProject(Project project) {
    state = project;
  }

  /// Clears the current project
  void clearProject() {
    state = null;
  }

  /// Updates the current project
  Future<void> updateProject(Project project) async {
    try {
      final updatedProject = await _projectService.updateProject(project);
      state = updatedProject;
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes the current project
  Future<void> deleteProject() async {
    if (state == null) return;

    try {
      await _projectService.deleteProject(state!.id);
      state = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Imports images to the current project
  Future<List<ImageItem>> importImages(String imagesDirectory) async {
    if (state == null) throw StateError('No project loaded');

    try {
      final images = await _projectService.importImages(state!.id, imagesDirectory);
      // Refresh project statistics after importing images
      final updatedProject = await _projectService.loadProject(state!.id);
      if (updatedProject != null) {
        state = updatedProject;
      }
      return images;
    } catch (e) {
      rethrow;
    }
  }
}

/// State notifier for project list
class ProjectListNotifier extends StateNotifier<List<Project>> {
  final ProjectService _projectService;
  bool _isLoading = false;

  ProjectListNotifier(this._projectService) : super([]);

  /// Whether the provider is loading
  bool get isLoading => _isLoading;

  /// Loads all projects
  Future<void> loadProjects() async {
    _isLoading = true;
    try {
      final projects = await _projectService.getAllProjects();
      state = projects;
    } catch (e) {
      state = [];
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Refreshes the project list
  Future<void> refresh() async {
    await loadProjects();
  }

  /// Adds a new project to the list
  void addProject(Project project) {
    state = [...state, project];
  }

  /// Removes a project from the list
  void removeProject(String projectId) {
    state = state.where((project) => project.id != projectId).toList();
  }

  /// Updates a project in the list
  void updateProject(Project updatedProject) {
    state = state.map((project) {
      return project.id == updatedProject.id ? updatedProject : project;
    }).toList();
  }
}
