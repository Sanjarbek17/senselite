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
import '../models/image_item.dart';
import 'database_helper.dart';

/// Data Access Object for ImageItem operations
class ImageDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Creates a new image in the database
  Future<void> insert(ImageItem image) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'images',
      _imageToMap(image),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Creates multiple images in the database
  Future<void> insertBatch(List<ImageItem> images) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    for (final image in images) {
      batch.insert(
        'images',
        _imageToMap(image),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Updates an existing image in the database
  Future<void> update(ImageItem image) async {
    final db = await _databaseHelper.database;
    await db.update(
      'images',
      _imageToMap(image),
      where: 'id = ?',
      whereArgs: [image.id],
    );
  }

  /// Deletes an image from the database
  Future<void> delete(String imageId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'images',
      where: 'id = ?',
      whereArgs: [imageId],
    );
  }

  /// Deletes all images for a project
  Future<void> deleteByProject(String projectId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'images',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
  }

  /// Retrieves an image by its ID
  Future<ImageItem?> getById(String imageId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'images',
      where: 'id = ?',
      whereArgs: [imageId],
    );

    if (maps.isNotEmpty) {
      return _imageFromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all images for a project
  Future<List<ImageItem>> getByProject(String projectId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'images',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'filename ASC',
    );
    return maps.map((map) => _imageFromMap(map)).toList();
  }

  /// Retrieves images with pagination
  Future<List<ImageItem>> getByProjectPaginated(
    String projectId, {
    int offset = 0,
    int limit = 50,
  }) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'images',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'filename ASC',
      offset: offset,
      limit: limit,
    );
    return maps.map((map) => _imageFromMap(map)).toList();
  }

  /// Gets annotated images for a project
  Future<List<ImageItem>> getAnnotatedImages(String projectId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'images',
      where: 'project_id = ? AND is_annotated = 1',
      whereArgs: [projectId],
      orderBy: 'filename ASC',
    );
    return maps.map((map) => _imageFromMap(map)).toList();
  }

  /// Gets unannotated images for a project
  Future<List<ImageItem>> getUnannotatedImages(String projectId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'images',
      where: 'project_id = ? AND is_annotated = 0',
      whereArgs: [projectId],
      orderBy: 'filename ASC',
    );
    return maps.map((map) => _imageFromMap(map)).toList();
  }

  /// Updates annotation status of an image
  Future<void> updateAnnotationStatus(String imageId, bool isAnnotated, int annotationCount) async {
    final db = await _databaseHelper.database;
    await db.update(
      'images',
      {
        'is_annotated': isAnnotated ? 1 : 0,
        'annotation_count': annotationCount,
      },
      where: 'id = ?',
      whereArgs: [imageId],
    );
  }

  /// Gets total image count for a project
  Future<int> getCountByProject(String projectId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM images WHERE project_id = ?',
      [projectId],
    );
    return result.first['count'] as int;
  }

  /// Gets annotated image count for a project
  Future<int> getAnnotatedCountByProject(String projectId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM images WHERE project_id = ? AND is_annotated = 1',
      [projectId],
    );
    return result.first['count'] as int;
  }

  /// Searches images by filename
  Future<List<ImageItem>> searchByFilename(String projectId, String query) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'images',
      where: 'project_id = ? AND filename LIKE ?',
      whereArgs: [projectId, '%$query%'],
      orderBy: 'filename ASC',
    );
    return maps.map((map) => _imageFromMap(map)).toList();
  }

  /// Converts an ImageItem object to a database map
  Map<String, dynamic> _imageToMap(ImageItem image) {
    return {
      'id': image.id,
      'filename': image.filename,
      'file_path': image.filePath,
      'width': image.width,
      'height': image.height,
      'file_size': image.fileSize,
      'project_id': image.projectId,
      'is_annotated': image.isAnnotated ? 1 : 0,
      'annotation_count': image.annotationCount,
      'added_at': image.addedAt.millisecondsSinceEpoch,
    };
  }

  /// Converts a database map to an ImageItem object
  ImageItem _imageFromMap(Map<String, dynamic> map) {
    return ImageItem(
      id: map['id'] as String,
      filename: map['filename'] as String,
      filePath: map['file_path'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      fileSize: map['file_size'] as int,
      projectId: map['project_id'] as String,
      isAnnotated: (map['is_annotated'] as int) == 1,
      annotationCount: map['annotation_count'] as int? ?? 0,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    );
  }
}
