// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/annotation.dart';
import 'database_helper.dart';

/// Data Access Object for Annotation operations
class AnnotationDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Creates a new annotation in the database
  Future<void> insert(Annotation annotation) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'annotations',
      _annotationToMap(annotation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Creates multiple annotations in the database
  Future<void> insertBatch(List<Annotation> annotations) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    for (final annotation in annotations) {
      batch.insert(
        'annotations',
        _annotationToMap(annotation),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Updates an existing annotation in the database
  Future<void> update(Annotation annotation) async {
    final db = await _databaseHelper.database;
    await db.update(
      'annotations',
      _annotationToMap(annotation),
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
  }

  /// Deletes an annotation from the database
  Future<void> delete(String annotationId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'annotations',
      where: 'id = ?',
      whereArgs: [annotationId],
    );
  }

  /// Deletes all annotations for an image
  Future<void> deleteByImage(String imageId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'annotations',
      where: 'image_id = ?',
      whereArgs: [imageId],
    );
  }

  /// Deletes all annotations for a project
  Future<void> deleteByProject(String projectId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'annotations',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
  }

  /// Deletes all annotations for a label
  Future<void> deleteByLabel(String labelId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'annotations',
      where: 'label_id = ?',
      whereArgs: [labelId],
    );
  }

  /// Retrieves an annotation by its ID
  Future<Annotation?> getById(String annotationId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'annotations',
      where: 'id = ?',
      whereArgs: [annotationId],
    );

    if (maps.isNotEmpty) {
      return _annotationFromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all annotations for an image
  Future<List<Annotation>> getByImage(String imageId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'annotations',
      where: 'image_id = ?',
      whereArgs: [imageId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => _annotationFromMap(map)).toList();
  }

  /// Retrieves all annotations for a project
  Future<List<Annotation>> getByProject(String projectId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'annotations',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => _annotationFromMap(map)).toList();
  }

  /// Retrieves all annotations for a specific label
  Future<List<Annotation>> getByLabel(String labelId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'annotations',
      where: 'label_id = ?',
      whereArgs: [labelId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => _annotationFromMap(map)).toList();
  }

  /// Gets annotations by type for a project
  Future<List<Annotation>> getByType(String projectId, AnnotationType type) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'annotations',
      where: 'project_id = ? AND type = ?',
      whereArgs: [projectId, type.name],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => _annotationFromMap(map)).toList();
  }

  /// Gets annotation count for an image
  Future<int> getCountByImage(String imageId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM annotations WHERE image_id = ?',
      [imageId],
    );
    return result.first['count'] as int;
  }

  /// Gets annotation count for a project
  Future<int> getCountByProject(String projectId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM annotations WHERE project_id = ?',
      [projectId],
    );
    return result.first['count'] as int;
  }

  /// Gets annotation count for a label
  Future<int> getCountByLabel(String labelId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM annotations WHERE label_id = ?',
      [labelId],
    );
    return result.first['count'] as int;
  }

  /// Gets annotation statistics by type for a project
  Future<Map<AnnotationType, int>> getTypeStatistics(String projectId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT type, COUNT(*) as count FROM annotations WHERE project_id = ? GROUP BY type',
      [projectId],
    );

    final stats = <AnnotationType, int>{};
    for (final row in result) {
      final type = AnnotationType.values.byName(row['type'] as String);
      stats[type] = row['count'] as int;
    }

    return stats;
  }

  /// Converts an Annotation object to a database map
  Map<String, dynamic> _annotationToMap(Annotation annotation) {
    return {
      'id': annotation.id,
      'type': annotation.type.name,
      'label_id': annotation.labelId,
      'image_id': annotation.imageId,
      'project_id': annotation.projectId,
      'created_at': annotation.createdAt.millisecondsSinceEpoch,
      'updated_at': annotation.updatedAt.millisecondsSinceEpoch,
      'notes': annotation.notes,
      'data': jsonEncode(annotation.toJson()),
    };
  }

  /// Converts a database map to an Annotation object
  Annotation _annotationFromMap(Map<String, dynamic> map) {
    final data = jsonDecode(map['data'] as String) as Map<String, dynamic>;
    return Annotation.fromJson(data);
  }
}
