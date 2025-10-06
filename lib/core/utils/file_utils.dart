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
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

/// Utility functions for file operations
class FileUtils {
  /// Checks if a file extension is supported for images
  static bool isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    return AppConstants.supportedImageExtensions.contains(extension);
  }

  /// Gets the file size in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Gets image dimensions
  static Future<Map<String, int>?> getImageDimensions(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        return {
          'width': image.width,
          'height': image.height,
        };
      }
    } catch (e) {
      print('Error getting image dimensions: $e');
    }
    return null;
  }

  /// Formats file size to human-readable format
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Creates a directory if it doesn't exist
  static Future<void> ensureDirectoryExists(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Gets all image files from a directory
  static Future<List<File>> getImageFiles(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return [];

    final files = <File>[];
    await for (final entity in directory.list(recursive: false)) {
      if (entity is File && isImageFile(entity.path)) {
        files.add(entity);
      }
    }

    // Sort files by name
    files.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
    return files;
  }

  /// Validates if a path is safe for use
  static bool isValidPath(String filePath) {
    try {
      final normalized = path.normalize(filePath);
      return !normalized.contains('..') && path.isAbsolute(normalized);
    } catch (e) {
      return false;
    }
  }

  /// Generates a unique filename if the file already exists
  static String getUniqueFileName(String directoryPath, String fileName) {
    final extension = path.extension(fileName);
    final baseName = path.basenameWithoutExtension(fileName);
    String uniqueName = fileName;
    int counter = 1;

    while (File(path.join(directoryPath, uniqueName)).existsSync()) {
      uniqueName = '$baseName($counter)$extension';
      counter++;
    }

    return uniqueName;
  }

  /// Copies a file to a new location
  static Future<void> copyFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    final destinationFile = File(destinationPath);

    // Ensure destination directory exists
    await ensureDirectoryExists(path.dirname(destinationPath));

    await sourceFile.copy(destinationFile.path);
  }

  /// Deletes a file safely
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Gets relative path from base directory
  static String getRelativePath(String filePath, String basePath) {
    return path.relative(filePath, from: basePath);
  }

  /// Joins path components safely
  static String joinPath(List<String> components) {
    return path.joinAll(components);
  }

  /// Validates project directory structure
  static Future<bool> isValidProjectDirectory(String projectPath) async {
    final directory = Directory(projectPath);
    if (!await directory.exists()) return false;

    // Check if it's a writable directory
    try {
      final testFile = File(path.join(projectPath, '.test'));
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
