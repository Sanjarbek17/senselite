// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'package:sqflite/sqflite.dart';
import '../models/project.dart';
import 'database_helper.dart';

/// Data Access Object for Project operations
class ProjectDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Creates a new project in the database
  Future<void> insert(Project project) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'projects',
      _projectToMap(project),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing project in the database
  Future<void> update(Project project) async {
    final db = await _databaseHelper.database;
    await db.update(
      'projects',
      _projectToMap(project),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  /// Deletes a project from the database
  Future<void> delete(String projectId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  /// Retrieves a project by its ID
  Future<Project?> getById(String projectId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [projectId],
    );

    if (maps.isNotEmpty) {
      return _projectFromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all projects from the database
  Future<List<Project>> getAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('projects', orderBy: 'updated_at DESC');
    return maps.map((map) => _projectFromMap(map)).toList();
  }

  /// Gets recent projects (last 10)
  Future<List<Project>> getRecent({int limit = 10}) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'projects',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return maps.map((map) => _projectFromMap(map)).toList();
  }

  /// Searches projects by name
  Future<List<Project>> searchByName(String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'projects',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => _projectFromMap(map)).toList();
  }

  /// Updates project statistics (total images, annotated images)
  Future<void> updateStatistics(String projectId, int totalImages, int annotatedImages) async {
    final db = await _databaseHelper.database;
    await db.update(
      'projects',
      {
        'total_images': totalImages,
        'annotated_images': annotatedImages,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  /// Converts a Project object to a database map
  Map<String, dynamic> _projectToMap(Project project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'project_path': project.projectPath,
      'images_path': project.imagesPath,
      'created_at': project.createdAt.millisecondsSinceEpoch,
      'updated_at': project.updatedAt.millisecondsSinceEpoch,
      'total_images': project.totalImages,
      'annotated_images': project.annotatedImages,
    };
  }

  /// Converts a database map to a Project object
  Project _projectFromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      projectPath: map['project_path'] as String,
      imagesPath: map['images_path'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      totalImages: map['total_images'] as int? ?? 0,
      annotatedImages: map['annotated_images'] as int? ?? 0,
    );
  }
}
