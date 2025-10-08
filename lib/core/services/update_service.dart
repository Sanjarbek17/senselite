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
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_info.dart';

/// Service responsible for handling application updates on Windows
class UpdateService {
  static const String _updateUrlKey = 'update_check_url';
  static const String _lastCheckKey = 'last_update_check';
  static const String _autoCheckKey = 'auto_check_updates';
  static const String _checkIntervalKey = 'update_check_interval_hours';

  /// Default update check URL - replace with your actual update server
  static const String _defaultUpdateUrl = 'https://your-server.com/api/updates/check';

  /// Default check interval in hours
  static const int _defaultCheckInterval = 24;

  /// Minimum time between update checks in milliseconds
  static const int _minCheckInterval = 60 * 60 * 1000; // 1 hour

  final http.Client _httpClient;

  UpdateService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Checks for available updates from the remote server
  ///
  /// Returns an [UpdateInfo] object if an update is available,
  /// or null if no update is available or an error occurred.
  Future<UpdateInfo?> checkForUpdates({
    String? customUrl,
    bool forceCheck = false,
  }) async {
    try {
      if (!forceCheck && !await _shouldCheckForUpdates()) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final updateUrl = customUrl ?? prefs.getString(_updateUrlKey) ?? _defaultUpdateUrl;

      // Get current app version and build number
      final currentVersion = await _getCurrentVersion();
      final currentBuildNumber = await _getCurrentBuildNumber();

      final response = await _httpClient
          .get(
            Uri.parse(updateUrl),
            headers: {
              'User-Agent': 'SenseLite/$currentVersion',
              'Content-Type': 'application/json',
              'X-Current-Version': currentVersion,
              'X-Current-Build': currentBuildNumber.toString(),
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromJson(jsonData);

        // Update last check timestamp
        await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);

        // Check if this version is newer than current
        if (updateInfo.isNewerThan(currentVersion, currentBuildNumber)) {
          return updateInfo;
        }
      } else if (response.statusCode == 204) {
        // No update available
        await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
        return null;
      } else {
        throw Exception('Update check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to check for updates: $e');
    }

    return null;
  }

  /// Downloads an update file to the local system
  ///
  /// Returns the local file path where the update was downloaded.
  /// Throws an exception if the download fails or checksum verification fails.
  Future<String> downloadUpdate(
    UpdateInfo updateInfo, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(Uri.parse(updateInfo.downloadUrl).path);
      final filePath = path.join(tempDir.path, 'senselite_updates', fileName);

      // Create directory if it doesn't exist
      final file = File(filePath);
      await file.parent.create(recursive: true);

      // Download the file with progress tracking
      final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception('Download failed with status: ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength ?? updateInfo.fileSize;
      var downloadedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (onProgress != null && contentLength > 0) {
          onProgress(downloadedBytes / contentLength);
        }
      }

      await sink.close();

      // Verify file integrity using checksum
      await _verifyFileChecksum(filePath, updateInfo.checksum);

      return filePath;
    } catch (e) {
      throw Exception('Failed to download update: $e');
    }
  }

  /// Installs the downloaded update
  ///
  /// This method launches the installer and optionally closes the current application.
  /// Returns true if the installation was initiated successfully.
  Future<bool> installUpdate(
    String installerPath, {
    bool closeCurrentApp = true,
  }) async {
    try {
      if (!File(installerPath).existsSync()) {
        throw Exception('Installer file not found: $installerPath');
      }

      final uri = Uri.file(installerPath);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched && closeCurrentApp) {
          // Give the installer a moment to start before closing
          await Future.delayed(const Duration(seconds: 2));
          exit(0);
        }

        return launched;
      } else {
        throw Exception('Cannot launch installer');
      }
    } catch (e) {
      throw Exception('Failed to install update: $e');
    }
  }

  /// Configures automatic update checking
  Future<void> setAutoUpdateConfig({
    required bool enabled,
    int checkIntervalHours = _defaultCheckInterval,
    String? updateUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_autoCheckKey, enabled);
    await prefs.setInt(_checkIntervalKey, checkIntervalHours);

    if (updateUrl != null) {
      await prefs.setString(_updateUrlKey, updateUrl);
    }
  }

  /// Gets the current auto-update configuration
  Future<Map<String, dynamic>> getAutoUpdateConfig() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'enabled': prefs.getBool(_autoCheckKey) ?? true,
      'intervalHours': prefs.getInt(_checkIntervalKey) ?? _defaultCheckInterval,
      'updateUrl': prefs.getString(_updateUrlKey) ?? _defaultUpdateUrl,
      'lastCheck': prefs.getInt(_lastCheckKey),
    };
  }

  /// Cleans up old update files to free disk space
  Future<void> cleanupOldUpdates() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final updatesDir = Directory(path.join(tempDir.path, 'senselite_updates'));

      if (await updatesDir.exists()) {
        final files = await updatesDir.list().toList();
        final now = DateTime.now();

        for (final entity in files) {
          if (entity is File) {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);

            // Delete files older than 7 days
            if (age.inDays > 7) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors - not critical
    }
  }

  /// Checks if we should perform an update check based on the configured interval
  Future<bool> _shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();

    final autoCheck = prefs.getBool(_autoCheckKey) ?? true;
    if (!autoCheck) return false;

    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final intervalHours = prefs.getInt(_checkIntervalKey) ?? _defaultCheckInterval;
    final intervalMs = intervalHours * 60 * 60 * 1000;

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastCheck = now - lastCheck;

    return timeSinceLastCheck >= intervalMs.clamp(_minCheckInterval, double.infinity);
  }

  /// Gets the current application version
  Future<String> _getCurrentVersion() async {
    // In a real app, you might get this from package_info_plus or similar
    return '1.0.0';
  }

  /// Gets the current application build number
  Future<int> _getCurrentBuildNumber() async {
    // In a real app, you might get this from package_info_plus or similar
    return 1;
  }

  /// Verifies the downloaded file matches the expected checksum
  Future<void> _verifyFileChecksum(String filePath, String expectedChecksum) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualChecksum = digest.toString();

    if (actualChecksum.toLowerCase() != expectedChecksum.toLowerCase()) {
      await file.delete(); // Remove corrupted file
      throw Exception('File checksum verification failed. Expected: $expectedChecksum, Got: $actualChecksum');
    }
  }

  /// Disposes of resources used by the service
  void dispose() {
    _httpClient.close();
  }
}
