// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

/// Represents information about an available application update
class UpdateInfo {
  /// The version string of the available update
  final String version;

  /// The build number of the available update
  final int buildNumber;

  /// The download URL for the update installer
  final String downloadUrl;

  /// The SHA256 checksum of the update file for verification
  final String checksum;

  /// The size of the update file in bytes
  final int fileSize;

  /// Release notes describing what's new in this version
  final String releaseNotes;

  /// Whether this is a critical/mandatory update
  final bool isCritical;

  /// The minimum version required to apply this update
  final String? minimumVersion;

  /// The date when this version was released
  final DateTime releaseDate;

  /// Creates a new UpdateInfo instance
  const UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.checksum,
    required this.fileSize,
    required this.releaseNotes,
    required this.isCritical,
    this.minimumVersion,
    required this.releaseDate,
  });

  /// Creates an UpdateInfo instance from a JSON map
  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      downloadUrl: json['downloadUrl'] as String,
      checksum: json['checksum'] as String,
      fileSize: json['fileSize'] as int,
      releaseNotes: json['releaseNotes'] as String,
      isCritical: json['isCritical'] as bool? ?? false,
      minimumVersion: json['minimumVersion'] as String?,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
    );
  }

  /// Converts this UpdateInfo instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'downloadUrl': downloadUrl,
      'checksum': checksum,
      'fileSize': fileSize,
      'releaseNotes': releaseNotes,
      'isCritical': isCritical,
      'minimumVersion': minimumVersion,
      'releaseDate': releaseDate.toIso8601String(),
    };
  }

  /// Compares version numbers to determine if this update is newer than the current version
  bool isNewerThan(String currentVersion, int currentBuildNumber) {
    // Simple version comparison - you might want to use a more sophisticated
    // version comparison library like 'version' package
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final updateParts = version.split('.').map(int.parse).toList();

    // Compare major.minor.patch
    for (int i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final updatePart = i < updateParts.length ? updateParts[i] : 0;

      if (updatePart > currentPart) return true;
      if (updatePart < currentPart) return false;
    }

    // If versions are equal, compare build numbers
    return buildNumber > currentBuildNumber;
  }

  @override
  String toString() {
    return 'UpdateInfo(version: $version, buildNumber: $buildNumber, '
        'isCritical: $isCritical, releaseDate: $releaseDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateInfo && other.version == version && other.buildNumber == buildNumber && other.downloadUrl == downloadUrl;
  }

  @override
  int get hashCode {
    return version.hashCode ^ buildNumber.hashCode ^ downloadUrl.hashCode;
  }
}
