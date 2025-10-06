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
import 'package:sqflite/sqflite.dart';
import '../models/label.dart';
import 'database_helper.dart';

/// Data Access Object for Label operations
class LabelDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Creates a new label in the database
  Future<void> insert(Label label) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'labels',
      _labelToMap(label),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Creates multiple labels in the database
  Future<void> insertBatch(List<Label> labels) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    for (final label in labels) {
      batch.insert(
        'labels',
        _labelToMap(label),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Updates an existing label in the database
  Future<void> update(Label label) async {
    final db = await _databaseHelper.database;
    await db.update(
      'labels',
      _labelToMap(label),
      where: 'id = ?',
      whereArgs: [label.id],
    );
  }

  /// Deletes a label from the database
  Future<void> delete(String labelId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'labels',
      where: 'id = ?',
      whereArgs: [labelId],
    );
  }

  /// Deletes all labels for a project
  Future<void> deleteByProject(String projectId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'labels',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
  }

  /// Retrieves a label by its ID
  Future<Label?> getById(String labelId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'labels',
      where: 'id = ?',
      whereArgs: [labelId],
    );

    if (maps.isNotEmpty) {
      return _labelFromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all labels for a project
  Future<List<Label>> getByProject(String projectId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'labels',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => _labelFromMap(map)).toList();
  }

  /// Retrieves a label by name for a project
  Future<Label?> getByName(String projectId, String name) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'labels',
      where: 'project_id = ? AND name = ?',
      whereArgs: [projectId, name],
    );

    if (maps.isNotEmpty) {
      return _labelFromMap(maps.first);
    }
    return null;
  }

  /// Retrieves a label by shortcut for a project
  Future<Label?> getByShortcut(String projectId, String shortcut) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'labels',
      where: 'project_id = ? AND shortcut = ?',
      whereArgs: [projectId, shortcut],
    );

    if (maps.isNotEmpty) {
      return _labelFromMap(maps.first);
    }
    return null;
  }

  /// Searches labels by name
  Future<List<Label>> searchByName(String projectId, String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'labels',
      where: 'project_id = ? AND name LIKE ?',
      whereArgs: [projectId, '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => _labelFromMap(map)).toList();
  }

  /// Updates label annotation count
  Future<void> updateAnnotationCount(String labelId, int count) async {
    final db = await _databaseHelper.database;
    await db.update(
      'labels',
      {'annotation_count': count},
      where: 'id = ?',
      whereArgs: [labelId],
    );
  }

  /// Gets label count for a project
  Future<int> getCountByProject(String projectId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM labels WHERE project_id = ?',
      [projectId],
    );
    return result.first['count'] as int;
  }

  /// Checks if a label name is unique in a project
  Future<bool> isNameUnique(String projectId, String name, {String? excludeId}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'project_id = ? AND name = ?';
    List<dynamic> whereArgs = [projectId, name];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM labels WHERE $whereClause',
      whereArgs,
    );
    return (result.first['count'] as int) == 0;
  }

  /// Checks if a shortcut is unique in a project
  Future<bool> isShortcutUnique(String projectId, String shortcut, {String? excludeId}) async {
    final db = await _databaseHelper.database;
    String whereClause = 'project_id = ? AND shortcut = ?';
    List<dynamic> whereArgs = [projectId, shortcut];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM labels WHERE $whereClause',
      whereArgs,
    );
    return (result.first['count'] as int) == 0;
  }

  /// Converts a Label object to a database map
  Map<String, dynamic> _labelToMap(Label label) {
    return {
      'id': label.id,
      'name': label.name,
      'color': label.color.value,
      'project_id': label.projectId,
      'description': label.description,
      'shortcut': label.shortcut,
      'annotation_count': label.annotationCount,
      'created_at': label.createdAt.millisecondsSinceEpoch,
    };
  }

  /// Converts a database map to a Label object
  Label _labelFromMap(Map<String, dynamic> map) {
    return Label(
      id: map['id'] as String,
      name: map['name'] as String,
      color: Color(map['color'] as int),
      projectId: map['project_id'] as String,
      description: map['description'] as String?,
      shortcut: map['shortcut'] as String?,
      annotationCount: map['annotation_count'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
