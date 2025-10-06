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
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../../core/models/project.dart';
import '../../../core/models/image_item.dart';
import '../../../core/database/project_dao.dart';
import '../../../core/database/image_dao.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/constants/app_constants.dart';

/// Service for managing projects
class ProjectService {
  final ProjectDao _projectDao = ProjectDao();
  final ImageDao _imageDao = ImageDao();
  final Uuid _uuid = const Uuid();

  /// Creates a new project
  Future<Project> createProject({
    required String name,
    required String projectPath,
    required String imagesPath,
    String? description,
  }) async {
    // Validate inputs
    if (name.isEmpty || name.length > AppConstants.maxProjectNameLength) {
      throw ArgumentError('Invalid project name length');
    }

    if (!await FileUtils.isValidProjectDirectory(projectPath)) {
      throw ArgumentError('Invalid project directory');
    }

    // Ensure project directory exists
    await FileUtils.ensureDirectoryExists(projectPath);

    // Create project instance
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      projectPath: projectPath,
      imagesPath: imagesPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save project to database
    await _projectDao.insert(project);

    // Create project file
    await _saveProjectFile(project);

    return project;
  }

  /// Loads a project from the database
  Future<Project?> loadProject(String projectId) async {
    return await _projectDao.getById(projectId);
  }

  /// Gets all projects
  Future<List<Project>> getAllProjects() async {
    return await _projectDao.getAll();
  }

  /// Gets recent projects
  Future<List<Project>> getRecentProjects({int limit = 10}) async {
    return await _projectDao.getRecent(limit: limit);
  }

  /// Searches projects by name
  Future<List<Project>> searchProjects(String query) async {
    return await _projectDao.searchByName(query);
  }

  /// Updates project information
  Future<Project> updateProject(Project project) async {
    final updatedProject = project.copyWith(
      updatedAt: DateTime.now(),
    );

    await _projectDao.update(updatedProject);
    await _saveProjectFile(updatedProject);

    return updatedProject;
  }

  /// Deletes a project and all its data
  Future<void> deleteProject(String projectId) async {
    final project = await _projectDao.getById(projectId);
    if (project == null) return;

    // Delete from database (cascade will handle related data)
    await _projectDao.delete(projectId);

    // Delete project files
    try {
      final projectFile = File(path.join(project.projectPath, AppConstants.projectFileName));
      if (await projectFile.exists()) {
        await projectFile.delete();
      }
    } catch (e) {
      print('Error deleting project files: $e');
    }
  }

  /// Imports images to a project
  Future<List<ImageItem>> importImages(String projectId, String imagesDirectory) async {
    final project = await _projectDao.getById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found');
    }

    // Get all image files from the directory
    final imageFiles = await FileUtils.getImageFiles(imagesDirectory);
    final imageItems = <ImageItem>[];

    for (final file in imageFiles) {
      try {
        // Get image dimensions
        final dimensions = await FileUtils.getImageDimensions(file.path);
        if (dimensions == null) continue;

        // Get file size
        final fileSize = await FileUtils.getFileSize(file.path);

        // Create ImageItem
        final imageItem = ImageItem(
          id: _uuid.v4(),
          filename: path.basename(file.path),
          filePath: file.path,
          width: dimensions['width']!,
          height: dimensions['height']!,
          fileSize: fileSize,
          projectId: projectId,
          addedAt: DateTime.now(),
        );

        imageItems.add(imageItem);
      } catch (e) {
        print('Error processing image ${file.path}: $e');
        continue;
      }
    }

    // Save images to database
    if (imageItems.isNotEmpty) {
      await _imageDao.insertBatch(imageItems);

      // Update project statistics
      final totalImages = await _imageDao.getCountByProject(projectId);
      final annotatedImages = await _imageDao.getAnnotatedCountByProject(projectId);
      await _projectDao.updateStatistics(projectId, totalImages, annotatedImages);
    }

    return imageItems;
  }

  /// Gets images for a project
  Future<List<ImageItem>> getProjectImages(String projectId) async {
    return await _imageDao.getByProject(projectId);
  }

  /// Gets project statistics
  Future<Map<String, dynamic>> getProjectStatistics(String projectId) async {
    final totalImages = await _imageDao.getCountByProject(projectId);
    final annotatedImages = await _imageDao.getAnnotatedCountByProject(projectId);

    return {
      'totalImages': totalImages,
      'annotatedImages': annotatedImages,
      'progress': totalImages > 0 ? (annotatedImages / totalImages) : 0.0,
    };
  }

  /// Exports project data
  Future<Map<String, dynamic>> exportProjectData(String projectId) async {
    final project = await _projectDao.getById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found');
    }

    final images = await _imageDao.getByProject(projectId);

    return {
      'project': project.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': AppConstants.appVersion,
    };
  }

  /// Imports project from exported data
  Future<Project> importProjectData(Map<String, dynamic> data, String newProjectPath) async {
    final projectData = data['project'] as Map<String, dynamic>;
    final imagesData = data['images'] as List<dynamic>;

    // Create new project with new ID and path
    final project = Project.fromJson(projectData).copyWith(
      id: _uuid.v4(),
      projectPath: newProjectPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save project
    await _projectDao.insert(project);

    // Import images
    final imageItems = <ImageItem>[];
    for (final imageData in imagesData) {
      final imageItem = ImageItem.fromJson(imageData as Map<String, dynamic>).copyWith(
        id: _uuid.v4(),
        projectId: project.id,
        addedAt: DateTime.now(),
      );
      imageItems.add(imageItem);
    }

    if (imageItems.isNotEmpty) {
      await _imageDao.insertBatch(imageItems);
    }

    return project;
  }

  /// Saves project data to a JSON file
  Future<void> _saveProjectFile(Project project) async {
    try {
      final projectFile = File(path.join(project.projectPath, AppConstants.projectFileName));
      final projectData = {
        'project': project.toJson(),
        'lastSaved': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
      };

      await projectFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(projectData),
      );
    } catch (e) {
      print('Error saving project file: $e');
    }
  }

  /// Validates project directory structure
  Future<bool> validateProjectDirectory(String projectPath) async {
    return await FileUtils.isValidProjectDirectory(projectPath);
  }

  /// Gets project from directory (if project.json exists)
  Future<Project?> getProjectFromDirectory(String projectPath) async {
    try {
      final projectFile = File(path.join(projectPath, AppConstants.projectFileName));
      if (!await projectFile.exists()) return null;

      final content = await projectFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final projectData = data['project'] as Map<String, dynamic>;

      return Project.fromJson(projectData);
    } catch (e) {
      print('Error reading project file: $e');
      return null;
    }
  }
}
